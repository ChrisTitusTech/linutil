use std::{
    cell::{Cell, RefCell},
    io::Write,
    sync::{Arc, Mutex},
    thread::JoinHandle,
};

use crate::{float::FloatContent, hint::Shortcut};

use crossterm::event::{KeyCode, KeyEvent, KeyModifiers};

use oneshot::{channel, Receiver};

use portable_pty::{
    ChildKiller, CommandBuilder, ExitStatus, MasterPty, NativePtySystem, PtySize, PtySystem,
};

use ratatui::{
    layout::Rect,
    style::{Style, Stylize},
    text::Line,
    Frame,
};

use tui_term::{
    vt100::{self, Screen},
    widget::PseudoTerminal,
};

use linutil_core::Command;

pub struct RunningCommand {
    /// A buffer to save all the command output (accumulates, until the command exits)
    buffer: Arc<Mutex<Vec<u8>>>,
    /// A handle for the thread running the command
    command_thread: Cell<Option<JoinHandle<ExitStatus>>>,
    /// A handle to kill the running process; it's an option because it can only be used once
    child_killer: Option<Receiver<Box<dyn ChildKiller + Send + Sync>>>,
    /// A join handle for the thread that reads command output and sends it to the main thread
    _reader_thread: JoinHandle<()>,
    /// Virtual terminal (pty) handle, used for resizing the pty
    pty_master: Box<dyn MasterPty + Send>,
    /// Used for sending keys to the emulated terminal
    writer: Box<dyn Write + Send>,
    /// Only set after the process has ended
    status: RefCell<Option<ExitStatus>>,
    scroll_offset: usize,
}

impl FloatContent for RunningCommand {
    fn top_title(&self) -> Option<Line<'_>> {
        let (content, content_style) = if !self.is_finished() {
            (" Running command... ", Style::default().reversed())
        } else if self.wait_command().success() {
            (" Success ", Style::default().green().reversed())
        } else {
            (" Failed ", Style::default().red().reversed())
        };

        Some(Line::from(content).style(content_style))
    }

    fn bottom_title(&self) -> Option<Line<'_>> {
        Some(Line::from("Press Ctrl-C to KILL the command"))
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect) {
        // Process the buffer and create the pseudo-terminal widget
        let screen = self.screen(area);
        let pseudo_term = PseudoTerminal::new(&screen);

        // Render the widget on the frame
        frame.render_widget(pseudo_term, area);
    }

    /// Handle key events of the running command "window". Returns true when the "window" should be
    /// closed
    fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        match key.code {
            // Handle Ctrl-C to kill the command
            KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                self.kill_child();
            }
            // Close the window when Enter is pressed and the command is finished
            KeyCode::Enter if self.is_finished() => {
                return true;
            }
            KeyCode::PageUp => {
                self.scroll_offset = self.scroll_offset.saturating_add(10);
            }
            KeyCode::PageDown => {
                self.scroll_offset = self.scroll_offset.saturating_sub(10);
            }
            // Pass other key events to the terminal
            _ => self.handle_passthrough_key_event(key),
        }
        false
    }

    fn is_finished(&self) -> bool {
        self.status.borrow().is_some()
    }

    fn get_shortcut_list(&self) -> (&str, Box<[Shortcut]>) {
        if self.is_finished() {
            (
                "Finished command",
                Box::new([
                    Shortcut::new("Close window", ["Enter", "q"]),
                    Shortcut::new("Scroll up", ["Page up"]),
                    Shortcut::new("Scroll down", ["Page down"]),
                ]),
            )
        } else {
            (
                "Running command",
                Box::new([
                    Shortcut::new("Kill the command", ["CTRL-c"]),
                    Shortcut::new("Scroll up", ["Page up"]),
                    Shortcut::new("Scroll down", ["Page down"]),
                ]),
            )
        }
    }
}

impl RunningCommand {
    pub fn new(commands: Vec<Command>) -> Self {
        let pty_system = NativePtySystem::default();

        // Build the command based on the provided Command enum variant
        let mut cmd: CommandBuilder = CommandBuilder::new("sh");
        cmd.arg("-c");

        // All the merged commands are passed as a single argument to reduce the overhead of rebuilding the command arguments for each and every command
        let mut script = String::new();
        for command in commands {
            match command {
                Command::Raw(prompt) => script.push_str(&format!("{}\n", prompt)),
                Command::LocalFile {
                    executable,
                    args,
                    file,
                } => {
                    if let Some(parent_directory) = file.parent() {
                        script.push_str(&format!("cd {}\n", parent_directory.display()));
                    }
                    script.push_str(&executable);
                    for arg in args {
                        script.push(' ');
                        script.push_str(&arg);
                    }
                    script.push('\n'); // Ensures that each command is properly separated for execution preventing directory errors
                }
                Command::None => panic!("Command::None was treated as a command"),
            }
        }

        cmd.arg(script);

        // Open a pseudo-terminal with initial size
        let pair = pty_system
            .openpty(PtySize {
                rows: 24, // Initial number of rows (will be updated dynamically)
                cols: 80, // Initial number of columns (will be updated dynamically)
                pixel_width: 0,
                pixel_height: 0,
            })
            .unwrap();

        let (tx, rx) = channel();
        // Thread waiting for the child to complete
        let command_handle = std::thread::spawn(move || {
            let mut child = pair.slave.spawn_command(cmd).unwrap();
            let killer = child.clone_killer();
            tx.send(killer).unwrap();
            child.wait().unwrap()
        });

        let mut reader = pair.master.try_clone_reader().unwrap(); // This is a reader, this is where we

        // A buffer, shared between the thread that reads the command output, and the main tread.
        // The main thread only reads the contents
        let command_buffer: Arc<Mutex<Vec<u8>>> = Arc::new(Mutex::new(Vec::new()));
        let reader_handle = {
            // Arc is just a reference, so we can create an owned copy without any problem
            let command_buffer = command_buffer.clone();
            // The closure below moves all variables used into it, so we can no longer use them,
            // that's why command_buffer.clone(), because we need to use command_buffer later
            std::thread::spawn(move || {
                let mut buf = [0u8; 8192];
                loop {
                    let size = reader.read(&mut buf).unwrap(); // Can block here
                    if size == 0 {
                        break; // EOF
                    }
                    let mut mutex = command_buffer.lock(); // Only lock the mutex after the read is
                                                           // done, to minimise the time it is opened
                    let command_buffer = mutex.as_mut().unwrap();
                    command_buffer.extend_from_slice(&buf[0..size]);
                    // The mutex is closed here automatically
                }
            })
        };

        let writer = pair.master.take_writer().unwrap();
        Self {
            buffer: command_buffer,
            command_thread: Some(command_handle).into(),
            child_killer: rx.into(),
            _reader_thread: reader_handle,
            pty_master: pair.master,
            writer,
            status: None.into(),
            scroll_offset: 0,
        }
    }

    fn screen(&mut self, size: Rect) -> Screen {
        // Resize the emulated pty
        self.pty_master
            .resize(PtySize {
                rows: size.height,
                cols: size.width,
                pixel_width: 0,
                pixel_height: 0,
            })
            .unwrap();

        // Process the buffer with a parser with the current screen size
        // We don't actually need to create a new parser every time, but it is so much easier this
        // way, and doesn't cost that much
        let mut parser = vt100::Parser::new(size.height, size.width, 200);
        let mutex = self.buffer.lock();
        let buffer = mutex.as_ref().unwrap();
        parser.process(buffer);
        // Adjust the screen content based on the scroll offset
        parser.screen_mut().set_scrollback(self.scroll_offset);
        parser.screen().clone()
    }

    /// This function will block if the command is not finished
    fn wait_command(&self) -> ExitStatus {
        let status = { self.status.borrow().clone() };
        match status {
            Some(status) => status,
            None => {
                let handle = self.command_thread.take().unwrap();
                let exit_status = handle.join().unwrap();
                self.status.replace(Some(exit_status.clone()));
                exit_status
            }
        }
    }

    /// Send SIGHUB signal, *not* SIGKILL or SIGTERM, to the child process
    pub fn kill_child(&mut self) {
        if !self.is_finished() {
            let mut killer = self.child_killer.take().unwrap().recv().unwrap();
            killer.kill().unwrap();
            self.wait_command();
        }
    }

    /// Convert the KeyEvent to pty key codes, and send them to the virtual terminal
    fn handle_passthrough_key_event(&mut self, key: &KeyEvent) {
        let input_bytes = match key.code {
            KeyCode::Char(ch) => {
                let raw_utf8 = || ch.to_string().into_bytes();

                match ch.to_ascii_uppercase() {
                    _ if key.modifiers != KeyModifiers::CONTROL => raw_utf8(),
                    // https://github.com/fyne-io/terminal/blob/master/input.go
                    // https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b
                    '2' | '@' | ' ' => vec![0],
                    '3' | '[' => vec![27],
                    '4' | '\\' => vec![28],
                    '5' | ']' => vec![29],
                    '6' | '^' => vec![30],
                    '7' | '-' | '_' => vec![31],
                    c if ('A'..='_').contains(&c) => {
                        let ascii_val = c as u8;
                        let ascii_to_send = ascii_val - 64;
                        vec![ascii_to_send]
                    }
                    _ => raw_utf8(),
                }
            }
            KeyCode::Enter => vec![b'\n'],
            KeyCode::Backspace => vec![0x7f],
            KeyCode::Left => vec![27, 91, 68],
            KeyCode::Right => vec![27, 91, 67],
            KeyCode::Up => vec![27, 91, 65],
            KeyCode::Down => vec![27, 91, 66],
            KeyCode::Tab => vec![9],
            KeyCode::Home => vec![27, 91, 72],
            KeyCode::End => vec![27, 91, 70],
            KeyCode::BackTab => vec![27, 91, 90],
            KeyCode::Delete => vec![27, 91, 51, 126],
            KeyCode::Insert => vec![27, 91, 50, 126],
            KeyCode::Esc => vec![27],
            _ => return,
        };
        // Send the keycodes to the virtual terminal
        let _ = self.writer.write_all(&input_bytes);
    }
}

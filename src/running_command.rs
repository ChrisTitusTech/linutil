use std::{
    io::Write,
    sync::{Arc, Mutex},
    thread::JoinHandle,
};

use crossterm::event::{KeyCode, KeyEvent, KeyModifiers};
use oneshot::{channel, Receiver};
use portable_pty::{
    ChildKiller, CommandBuilder, ExitStatus, MasterPty, NativePtySystem, PtySize, PtySystem,
};
use ratatui::{
    layout::Size,
    style::{Color, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, Borders},
    Frame,
};
use tui_term::{
    vt100::{self, Screen},
    widget::PseudoTerminal,
};

use crate::{float::floating_window, theme::get_theme};

/// This is a struct for storing everything connected to a running command
// Create a new instance on every new command you want to run
pub struct RunningCommand {
    /// A buffer to save all the command output (accumulates, untill the command exits)
    buffer: Arc<Mutex<Vec<u8>>>,

    /// A handle of the tread where the command is being executed
    command_thread: Option<JoinHandle<ExitStatus>>, 

    /// A handle to kill the running process, it's an option because it can only be used once
    child_killer: Option<Receiver<Box<dyn ChildKiller + Send + Sync>>>,

    /// A join handle for the thread that is reading all the command output and sending it to the
    /// main thread
    _reader_thread: JoinHandle<()>,

    /// Virtual terminal (pty) handle, used for resizing the pty
    pty_master: Box<dyn MasterPty + Send>,

    /// Used for sending keys to the emulated terminal
    writer: Box<dyn Write + Send>,

    /// Only set after the process has ended
    status: Option<ExitStatus>,
}

impl RunningCommand {
    pub fn new(command: &str) -> Self {
        let pty_system = NativePtySystem::default();
        let mut cmd = CommandBuilder::new("sh");
        cmd.arg("-c");
        cmd.arg(command);

        let cwd = std::env::current_dir().unwrap();
        cmd.cwd(cwd);

        let pair = pty_system
            .openpty(PtySize {
                rows: 24, // Set the initial size of the emulated terminal
                cols: 80, // We will update this later, if resized
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
            command_thread: Some(command_handle),
            child_killer: Some(rx),
            _reader_thread: reader_handle,
            pty_master: pair.master,
            writer,
            status: None,
        }
    }
    fn screen(&mut self, size: Size) -> Screen {
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
        let mut parser = vt100::Parser::new(size.height, size.width, 0);
        let mutex = self.buffer.lock();
        let buffer = mutex.as_ref().unwrap();
        parser.process(buffer);
        parser.screen().clone()
    }
    pub fn is_finished(&mut self) -> bool {
        if let Some(command_thread) = &self.command_thread {
            command_thread.is_finished()
        } else {
            true
        }
    }
    /// This function will block if the command is not finished
    fn get_exit_status(&mut self) -> ExitStatus {
        if self.command_thread.is_some() {
            let handle = self.command_thread.take().unwrap();
            let exit_status = handle.join().unwrap();
            self.status = Some(exit_status.clone());
            exit_status
        } else {
            self.status.as_ref().unwrap().clone()
        }
    }

    pub fn draw(&mut self, frame: &mut Frame) {
        {
            let theme = get_theme();
            // Funny name
            let floater = floating_window(frame.size());

            let inner_size = Size {
                width: floater.width - 2, // Because we add a `Block` with a border
                height: floater.height - 2,
            };

            // When the command is running
            let term_border = if !self.is_finished() {
                Block::default()
                    .borders(Borders::ALL)
                    .title_top(Line::from("Running the command....").centered())
                    .title_style(Style::default().reversed())
                    .title_bottom(Line::from("Press Ctrl-C to KILL the command"))
            } else {
                // This portion is just for pretty colors.
                // You can use multiple `Span`s with different styles each, to construct a line,
                // which can be used as a list item, or in this case a `Block` title

                let mut title_line = if self.get_exit_status().success() {
                    Line::from(
                        Span::default()
                            .content("SUCCESS!")
                            .style(Style::default().fg(theme.success_color).reversed()),
                    )
                } else {
                    Line::from(
                        Span::default()
                            .content("FAILED!")
                            .style(Style::default().fg(Color::Rgb(199, 55, 44)).reversed()),
                    )
                };

                title_line.push_span(
                    Span::default()
                        .content(" press <ENTER> to close this window ")
                        .style(Style::default()),
                );

                Block::default()
                    .borders(Borders::ALL)
                    .title_top(title_line.centered())
            };
            let screen = self.screen(inner_size); // when the terminal is changing a lot, there
                                                  // will be 1 frame of lag on resizing
            let pseudo_term = PseudoTerminal::new(&screen).block(term_border);
            frame.render_widget(pseudo_term, floater);
        }
    }
    /// Send SIGHUB signal, *not* SIGKILL or SIGTERM, to the child process
    pub fn kill_child(&mut self) {
        if !self.is_finished() {
            let mut killer = self.child_killer.take().unwrap().recv().unwrap();
            killer.kill().unwrap();
        }
    }

    /// Handle key events of the running command "window". Returns true when the "window" should be
    /// closed
    pub fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        match key.code {
            KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                self.kill_child()
            }

            KeyCode::Enter if self.is_finished() => {
                return true;
            }
            _ => self.handle_passthrough_key_event(key),
        };
        false
    }

    /// Convert the KeyEvent to pty key codes, and send them to the virtual terminal
    fn handle_passthrough_key_event(&mut self, key: &KeyEvent) {
        let input_bytes = match key.code {
            KeyCode::Char(ch) => {
                let mut send = vec![ch as u8];
                let upper = ch.to_ascii_uppercase();
                if key.modifiers == KeyModifiers::CONTROL {
                    match upper {
                        // https://github.com/fyne-io/terminal/blob/master/input.go
                        // https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b
                        '2' | '@' | ' ' => send = vec![0],
                        '3' | '[' => send = vec![27],
                        '4' | '\\' => send = vec![28],
                        '5' | ']' => send = vec![29],
                        '6' | '^' => send = vec![30],
                        '7' | '-' | '_' => send = vec![31],
                        char if ('A'..='_').contains(&char) => {
                            // Since A == 65,
                            // we can safely subtract 64 to get
                            // the corresponding control character
                            let ascii_val = char as u8;
                            let ascii_to_send = ascii_val - 64;
                            send = vec![ascii_to_send];
                        }
                        _ => {}
                    }
                }
                send
            }
            KeyCode::Enter => vec![b'\n'],
            KeyCode::Backspace => vec![8],
            KeyCode::Left => vec![27, 91, 68],
            KeyCode::Right => vec![27, 91, 67],
            KeyCode::Up => vec![27, 91, 65],
            KeyCode::Down => vec![27, 91, 66],
            KeyCode::Tab => vec![9],
            KeyCode::Home => vec![27, 91, 72],
            KeyCode::End => vec![27, 91, 70],
            KeyCode::PageUp => vec![27, 91, 53, 126],
            KeyCode::PageDown => vec![27, 91, 54, 126],
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
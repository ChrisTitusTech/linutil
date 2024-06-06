use std::{
    sync::{Arc, Mutex},
    thread::JoinHandle,
};

use oneshot::{channel, Receiver};
use portable_pty::{
    ChildKiller, CommandBuilder, ExitStatus, MasterPty, NativePtySystem, PtySize, PtySystem,
};
use ratatui::{
    layout::Size,
    style::{Color, Style, Styled, Stylize},
    text::{Line, Span},
    widgets::{Block, Borders},
    Frame,
};
use tui_term::{
    vt100::{self, Screen},
    widget::PseudoTerminal,
};

use crate::{float::floating_window, theme::get_theme};

// This is a struct for stoaring everything connected to a running command
// Create a new instance on every new command you want to run
pub struct RunningCommand {
    buffer: Arc<Mutex<Vec<u8>>>, // A buffer to save all the command output (accumulates, untill the command
    // exits)
    command_thread: Option<JoinHandle<ExitStatus>>, // the tread where the command is being executed
    child_killer: Option<Receiver<Box<dyn ChildKiller + Send + Sync>>>, // This is a thing that
    // will allow us to kill the running command on Ctrl-C
    // Also, don't mind the name :)

    //It is an option, because we want to be able to .join it, without
    // moving the whole RunningCommand struct, (we want to have the exit code, and still have acess
    // to the buffer, to render the terminal output)
    _reader_thread: JoinHandle<()>, // The thread that reads the command output, and sends it to us
    // by writing to the buffer. We need another thread, because the reader may block, and we want
    // our UI to stay responsive.
    pty_master: Box<dyn MasterPty + Send>, // This is a master handle of the emulated terminal, we
    // will use it to resize the emulated terminal
    status: Option<ExitStatus>, // We want to be able to get the exit status more then once, and
                                // this is a nice place to store it. We will put it here, after joining the reader_tread
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
                                                                  // are reading the command output from

        // This is a bit complicated, but I will try my best to explain :)
        // Arc<Mutex<>> Means that this object is an Async Reference Count (Arc) Mutex lock. We
        // need the ark part, because when all references holding that ark go out of scope, we want
        // the memory to get freed. Mutex is to allow us to write and read to the memory from
        // different threads, without fear that some thread will be reading when other is writing
        let command_buffer: Arc<Mutex<Vec<u8>>> = Arc::new(Mutex::new(Vec::new()));
        let reader_handle = {
            // Arc is just a reference, so we can create an owned copy without any problem
            let command_buffer = command_buffer.clone();
            // The closure below moves all variables used into it, so we can no longer use them,
            // thats why command_buffer.clone(), because we need to use command_buffer later
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
        Self {
            buffer: command_buffer,
            command_thread: Some(command_handle),
            child_killer: Some(rx),
            _reader_thread: reader_handle,
            pty_master: pair.master,
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
        // We don't actually need to create a new parser every time, but it is so much easyer this
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
    /// From what I observed this sends SIGHUB signal, *not* SIGKILL or SIGTERM, so the process
    /// doesn't get a chance to clean up. If neccesary, I can look into sending SIGTERM directly
    pub fn kill_child(&mut self) {
        if !self.is_finished() {
            let mut killer = self.child_killer.take().unwrap().recv().unwrap();
            killer.kill().unwrap();
        }
    }
}

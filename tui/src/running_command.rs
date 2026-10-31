use crate::{
    float::FloatContent,
    stars::{basic_terminal, linux_console},
    theme::Theme,
};
use linutil_core::Command;
use oneshot::{channel, Receiver};
use portable_pty::{
    ChildKiller, CommandBuilder, ExitStatus, MasterPty, NativePtySystem, PtySize, PtySystem,
};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, KeyModifiers, MouseEvent, MouseEventKind},
    prelude::*,
    widgets::Block,
};
use std::{
    fs::File,
    io::{Read, Result, Write},
    sync::{
        atomic::{AtomicBool, AtomicU32, Ordering},
        Arc, Mutex, OnceLock,
    },
    thread::JoinHandle,
    time::{Duration, Instant},
};
use time::{macros::format_description, OffsetDateTime};
use tui_term::widget::PseudoTerminal;
use vt100_ctt::{Parser, Screen};

#[cfg(unix)]
use nix::{
    errno::Errno,
    sys::signal::{kill, Signal},
    unistd::{getsid, Pid},
};

pub struct RunningCommand {
    /// A buffer to save all the command output (accumulates, until the command exits)
    buffer: Arc<Mutex<Vec<u8>>>,
    /// A handle for the thread running the command
    command_thread: Option<JoinHandle<ExitStatus>>,
    /// Channel to receive the child killer from the runner thread
    child_killer: Option<Receiver<Box<dyn ChildKiller + Send + Sync>>>,
    /// Cached child killer so kill_child can be called multiple times
    killer: Option<Box<dyn ChildKiller + Send + Sync>>,
    /// Child process ID (for process-group and session signaling on Unix)
    child_pid: Arc<AtomicU32>,
    /// Number of times kill_child has been invoked
    kill_count: usize,
    /// Why the last kill_child could not signal every process
    cancel_error: Option<&'static str>,
    /// A join handle for the thread that reads command output and sends it to the main thread
    reader_thread: JoinHandle<()>,
    /// Virtual terminal (pty) handle, used for resizing the pty
    pty_master: Box<dyn MasterPty + Send>,
    /// Used for sending keys to the emulated terminal
    writer: Box<dyn Write + Send>,
    /// Only set after the process has ended
    status: Option<ExitStatus>,
    log_path: Option<String>,
    scroll_offset: usize,
    /// When the result was first drawn, moved on by each key that came too soon to close it
    result_quiet_since: Option<Instant>,
}

/// How long keys must pause before one can close a result: long enough that
/// the key is a reaction to it, not one typed ahead or a held key repeating.
pub(crate) const RESULT_KEY_PAUSE: Duration = Duration::from_millis(300);

impl FloatContent for RunningCommand {
    fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &Theme) {
        // Define the block for the terminal display
        let block = if !self.is_finished() {
            // Display a block indicating the command is running
            Block::bordered()
                .border_set(crate::dashboard::border_set())
                .border_style(Style::default().fg(theme.focused_color()))
                .title_top(
                    Line::styled(
                        " Running Command ",
                        Style::default().fg(theme.tab_color()).bold(),
                    )
                    .centered(),
                )
                .title_bottom(
                    Line::styled(
                        self.cancel_hint(),
                        Style::default().fg(theme.unfocused_color()),
                    )
                    .centered(),
                )
                .style(Style::default().bg(theme.bg()).fg(theme.cmd_color()))
        } else {
            // Display a block with the command's exit status
            let is_invalid = self.check_invalid_choice();
            let (title_line, border_color) = if self.get_exit_status().success() && !is_invalid {
                (
                    Line::styled(" Success ", Style::default().fg(theme.tab_color()).bold()),
                    Color::Green,
                )
            } else {
                (
                    Line::styled(" Fail ", Style::default().fg(theme.tab_color()).bold()),
                    Color::Red,
                )
            };

            let log_path = if let Some(log_path) = &self.log_path {
                Line::styled(
                    format!(" Log saved: {log_path} "),
                    Style::default().fg(theme.unfocused_color()),
                )
            } else {
                Line::styled(
                    " Press 'l' to save command log ",
                    Style::default().fg(theme.unfocused_color()),
                )
            };

            Block::bordered()
                .border_set(crate::dashboard::border_set())
                .border_style(Style::default().fg(border_color).bold())
                .title_top(title_line.centered())
                .title_bottom(log_path.centered())
                .style(Style::default().bg(theme.bg()).fg(theme.cmd_color()))
        };

        // Calculate the inner size of the terminal area, considering borders
        let inner = block.inner(area);
        let inner_size = inner.as_size();
        // The parser panics on an empty screen, which a very narrow terminal
        // leaves, and on a double-width character in a single column.
        if inner_size.width < 2 || inner_size.height == 0 {
            frame.render_widget(block, area);
            return;
        }
        // Process the buffer and create the pseudo-terminal widget
        let screen = self.screen(inner_size);
        let pseudo_term = PseudoTerminal::new(&screen).block(block);

        // Render the widget on the frame
        frame.render_widget(pseudo_term, area);

        // Output left at the terminal's default colours takes the theme's, or the
        // window would show the terminal's own background inside the dashboard.
        let buffer = frame.buffer_mut();
        for position in inner.intersection(buffer.area).positions() {
            let cell = &mut buffer[position];
            if cell.bg == Color::Reset {
                cell.bg = theme.bg();
            }
            if cell.fg == Color::Reset {
                cell.fg = theme.cmd_color();
            }
        }
    }

    fn handle_mouse_event(&mut self, event: &MouseEvent) -> bool {
        match event.kind {
            MouseEventKind::ScrollUp => {
                self.scroll_offset = self.scroll_offset.saturating_add(1);
            }
            MouseEventKind::ScrollDown => {
                self.scroll_offset = self.scroll_offset.saturating_sub(1);
            }
            _ => {}
        }
        true
    }
    /// Handle key events of the running command "window". Returns true when the "window" should be
    /// closed
    fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        if self.is_finished() {
            match key.code {
                KeyCode::Char('c' | 'C') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                    return false;
                }
                KeyCode::PageUp => {
                    self.scroll_offset = self.scroll_offset.saturating_add(10);
                    return false;
                }
                KeyCode::PageDown => {
                    self.scroll_offset = self.scroll_offset.saturating_sub(10);
                    return false;
                }
                KeyCode::Char('l') => {
                    if let Ok(log_path) = self.save_log() {
                        self.log_path = Some(log_path);
                    }
                    return false;
                }
                _ => return self.key_closes_result(Instant::now()),
            }
        }

        match key.code {
            // Each press escalates. The window stays open until the command
            // has ended, so nothing keeps running out of sight.
            KeyCode::Char('c' | 'C') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                self.kill_child();
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
        // First check if the main command thread has finished
        if let Some(command_thread) = &self.command_thread {
            if !command_thread.is_finished() {
                return false;
            }
        }

        // On Unix, verify that no child processes remain in the process group
        #[cfg(unix)]
        {
            let pid = self.child_pid.load(Ordering::Acquire);
            if pid != 0 {
                let pgid = Pid::from_raw(-(pid as i32));
                // Signal 0 tests if any process in the process group is still alive
                if process_group_alive(kill(pgid, None)) {
                    return false;
                }
            }
        }

        // Verify the reader thread has finished draining output into the buffer
        if !self.reader_thread.is_finished() {
            return false;
        }

        true
    }

    fn result_pending(&self) -> bool {
        self.is_finished() && self.result_quiet_since.is_none()
    }
}
pub static TERMINAL_UPDATED: AtomicBool = AtomicBool::new(true);

/// All the merged commands are passed as a single argument to reduce the
/// overhead of rebuilding the command arguments for each and every command.
/// Every command runs even if an earlier one fails, but the batch exits
/// non-zero if any of them failed: a plain `sh -c` would report only the
/// last command's status, showing "Done" after a failed install.
/// The exit status of `invalidChoice` in common-script.sh.
const INVALID_CHOICE_STATUS: u32 = 64;

// Keeps the last failing status, so that an invalid choice is reported as such.
fn batch_script(commands: &[&Command]) -> String {
    let mut script = String::new();
    for command in commands {
        match command {
            // A subshell, so that an `exit` in one command does not end the batch.
            Command::Raw(prompt) => {
                script.push_str(&format!("(\n{prompt}\n) || linutil_failed=$?\n"))
            }
            Command::LocalFile {
                executable,
                args,
                file,
            } => {
                if let Some(parent_directory) = file.parent() {
                    script.push_str(&format!("cd {} && ", parent_directory.display()));
                }
                script.push_str(executable);
                for arg in args {
                    script.push(' ');
                    script.push_str(arg);
                }
                script.push_str(" || linutil_failed=$?\n");
            }
            Command::None => panic!("Command::None was treated as a command"),
        }
    }
    script.push_str("exit ${linutil_failed:-0}\n");
    script
}

/// Reads a signal 0 probe. Only ESRCH means the group is gone: EPERM means that
/// what is left belongs to another user, like a command started through sudo.
#[cfg(unix)]
fn process_group_alive(probe: nix::Result<()>) -> bool {
    probe != Err(Errno::ESRCH)
}

/// The bullet before "Done!"/"Failed!". The Linux console font has no `●`.
fn status_marker() -> &'static str {
    static MARKER: OnceLock<&'static str> = OnceLock::new();
    MARKER.get_or_init(|| {
        let term = std::env::var("TERM").unwrap_or_default();
        if basic_terminal(&term, linux_console()) {
            "*"
        } else {
            "●"
        }
    })
}

impl RunningCommand {
    pub fn new(commands: &[&Command]) -> Self {
        let pty_system = NativePtySystem::default();

        // Build the command based on the provided Command enum variant
        let mut cmd: CommandBuilder = CommandBuilder::new("sh");
        cmd.arg("-c");

        // Set environment variables needed for interactive TUI tools like gum
        cmd.env("TERM", "xterm-256color");
        cmd.env("COLORTERM", "truecolor");
        // Ensure that interactive tools can detect they're in a terminal
        cmd.env("FORCE_COLOR", "1");
        cmd.env("NO_COLOR", "");

        cmd.arg(batch_script(commands));

        // Open a pseudo-terminal with initial size
        let pair = pty_system
            .openpty(PtySize {
                rows: 24, // Initial number of rows (will be updated dynamically)
                cols: 80, // Initial number of columns (will be updated dynamically)
                pixel_width: 0,
                pixel_height: 0,
            })
            .unwrap();

        let child_pid = Arc::new(AtomicU32::new(0));
        let child_pid_clone = Arc::clone(&child_pid);
        let (tx, rx) = channel();
        // Thread waiting for the child to complete
        let command_handle = std::thread::spawn(move || {
            let mut child = pair.slave.spawn_command(cmd).unwrap();
            let killer = child.clone_killer();
            if let Some(pid) = child.process_id() {
                child_pid_clone.store(pid, Ordering::Release);
            }
            let _ = tx.send(killer);
            child.wait().unwrap()
        });

        let mut reader = pair.master.try_clone_reader().unwrap(); // This is a reader, this is where we

        // A buffer, shared between the thread that reads the command output, and the main tread.
        // The main thread only reads the contents
        let command_buffer: Arc<Mutex<Vec<u8>>> = Arc::new(Mutex::new(Vec::new()));
        TERMINAL_UPDATED.store(true, Ordering::Release);
        let reader_handle = {
            // Arc is just a reference, so we can create an owned copy without any problem
            let command_buffer = command_buffer.clone();
            // The closure below moves all variables used into it, so we can no longer use them,
            // that's why command_buffer.clone(), because we need to use command_buffer later
            std::thread::spawn(move || {
                let mut buf = [0u8; 8192];
                loop {
                    match reader.read(&mut buf) {
                        Ok(size) => {
                            if size == 0 {
                                break; // EOF
                            }
                            let mut mutex = command_buffer.lock(); // Only lock the mutex after the read is
                                                                   // done, to minimise the time it is opened
                            let command_buffer = mutex.as_mut().unwrap();
                            command_buffer.extend_from_slice(&buf[0..size]);
                            TERMINAL_UPDATED.store(true, Ordering::Release);
                            // The mutex is closed here automatically
                        }
                        Err(e) => {
                            eprintln!("Error reading from terminal: {e}");
                            break;
                        }
                    }
                }
                TERMINAL_UPDATED.store(true, Ordering::Release);
            })
        };

        let writer = pair.master.take_writer().unwrap();
        Self {
            buffer: command_buffer,
            command_thread: Some(command_handle),
            child_killer: Some(rx),
            killer: None,
            child_pid,
            kill_count: 0,
            cancel_error: None,
            reader_thread: reader_handle,
            pty_master: pair.master,
            writer,
            status: None,
            log_path: None,
            scroll_offset: 0,
            result_quiet_since: None,
        }
    }

    /// The footer while a command runs: what Ctrl-C does next, or why it failed.
    fn cancel_hint(&self) -> String {
        if let Some(error) = self.cancel_error {
            return format!(" Not stopped: {error} · Ctrl-C to retry ");
        }
        match self.kill_count {
            0 => " Ctrl-C to cancel ",
            1 => " Cancelling · Ctrl-C to terminate ",
            2 => " Terminating · Ctrl-C to force stop ",
            _ => " Force stop sent · Ctrl-C to retry ",
        }
        .to_string()
    }

    /// Only the exit status counts: the output may mention "invalid" for
    /// unrelated reasons, e.g. a failing tool's "invalid option".
    fn check_invalid_choice(&mut self) -> bool {
        self.get_exit_status().exit_code() == INVALID_CHOICE_STATUS
    }

    /// A key can arrive before the frame showing the result, and queued or held
    /// keys right after it. None of them may close a result nobody could read.
    fn key_closes_result(&mut self, now: Instant) -> bool {
        let Some(quiet_since) = &mut self.result_quiet_since else {
            return false;
        };
        let closes = now.saturating_duration_since(*quiet_since) >= RESULT_KEY_PAUSE;
        if !closes {
            *quiet_since = now;
        }
        closes
    }

    fn screen(&mut self, size: Size) -> Screen {
        if self.result_pending() {
            let is_invalid = self.check_invalid_choice();
            let (color, status) = if is_invalid {
                ("31", "Invalid!")
            } else if self.get_exit_status().success() {
                ("32", "Done!")
            } else {
                ("31", "Failed!")
            };
            let msg = format!(
                "\r\n\x1b[1;{color}m{} {status} Press any key to close . . .\x1b[0m\r\n",
                status_marker()
            );
            if let Ok(mut mutex) = self.buffer.lock() {
                mutex.extend_from_slice(msg.as_bytes());
            }
            self.result_quiet_since = Some(Instant::now());
            TERMINAL_UPDATED.store(true, Ordering::Release);
        }

        // Resize the emulated pty; ignore failures (e.g., pty already closed
        // after the child exited, or zero-dimension target on extreme resizes)
        // since the screen still renders from the existing buffer.
        let _ = self.pty_master.resize(PtySize {
            rows: size.height,
            cols: size.width,
            pixel_width: 0,
            pixel_height: 0,
        });

        // Process the buffer with a parser with the current screen size
        // We don't actually need to create a new parser every time, but it is so much easier this
        // way, and doesn't cost that much
        let mut parser = Parser::new(size.height, size.width, 1000);
        let mutex = self.buffer.lock();
        let buffer = mutex.as_ref().unwrap();
        parser.process(buffer);
        // Adjust the screen content based on the scroll offset
        parser.screen_mut().set_scrollback(self.scroll_offset);
        parser.screen().clone()
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

    /// Signal child process and process group to terminate
    pub fn kill_child(&mut self) {
        if self.is_finished() {
            return;
        }

        if self.killer.is_none() {
            if let Some(rx) = self.child_killer.take() {
                if let Ok(killer) = rx.try_recv() {
                    self.killer = Some(killer);
                } else {
                    self.child_killer = Some(rx);
                }
            }
        }

        let pid = self.child_pid.load(Ordering::Acquire);

        #[cfg(unix)]
        if pid != 0 {
            let error = match self.kill_count {
                // First Ctrl+C: Send SIGINT to process group and root process.
                // Do not send SIGHUP via killer.kill() here, as that terminates
                // the top-level shell process immediately and leaves child
                // processes (such as package managers, build processes, or subshells) orphaned.
                0 => Self::signal_group(pid, Signal::SIGINT),
                // Second Ctrl+C: Escalate to SIGTERM for process group and session.
                1 => Self::signal_group(pid, Signal::SIGTERM)
                    .or(self.kill_session_processes(pid, Signal::SIGTERM)),
                // Subsequent Ctrl+C: Force termination with SIGKILL.
                _ => {
                    let error = Self::signal_group(pid, Signal::SIGKILL)
                        .or(self.kill_session_processes(pid, Signal::SIGKILL));
                    if let Some(killer) = &mut self.killer {
                        let _ = killer.kill();
                    }
                    error
                }
            };
            self.cancel_error = error.map(Errno::desc);
        }

        #[cfg(not(unix))]
        if let Some(killer) = &mut self.killer {
            let _ = killer.kill();
        }

        self.kill_count += 1;
    }

    /// Signal the process group and its leader. A process that has already
    /// exited is not an error.
    #[cfg(unix)]
    fn signal_group(pid: u32, signal: Signal) -> Option<Errno> {
        let group = kill(Pid::from_raw(-(pid as i32)), signal);
        let leader = kill(Pid::from_raw(pid as i32), signal);
        [group, leader]
            .into_iter()
            .filter_map(|result| result.err())
            .find(|error| *error != Errno::ESRCH)
    }

    /// Signal the rest of the session. A permission error is returned: a group
    /// signal that reached some processes succeeds without saying so.
    #[cfg(unix)]
    fn kill_session_processes(&self, session_pid: u32, signal: Signal) -> Option<Errno> {
        let Ok(entries) = std::fs::read_dir("/proc") else {
            return None;
        };
        let mut denied = None;
        for entry in entries.flatten() {
            let file_name = entry.file_name();
            let Some(name_str) = file_name.to_str() else {
                continue;
            };
            let Ok(p) = name_str.parse::<i32>() else {
                continue;
            };
            if p <= 1 || p == session_pid as i32 {
                continue;
            }
            if let Ok(sid) = getsid(Some(Pid::from_raw(p))) {
                if sid.as_raw() == session_pid as i32
                    && kill(Pid::from_raw(p), signal) == Err(Errno::EPERM)
                {
                    denied = Some(Errno::EPERM);
                }
            }
        }
        denied
    }

    fn save_log(&self) -> Result<String> {
        let mut log_path = std::env::temp_dir();
        let date_format = format_description!("[year]-[month]-[day]-[hour]-[minute]-[second]");
        log_path.push(format!(
            "linutil_log_{}.log",
            OffsetDateTime::now_local()
                .unwrap_or(OffsetDateTime::now_utc())
                .format(&date_format)
                .unwrap()
        ));

        let mut file = File::create(&log_path)?;
        let buffer = self.buffer.lock().unwrap();
        file.write_all(&buffer)?;

        Ok(log_path.to_string_lossy().into_owned())
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
            KeyCode::Enter => vec![b'\r'],
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
        if let Err(e) = self.writer.write_all(&input_bytes) {
            eprintln!("Failed to write to terminal: {e}");
        }
        // Ensure the data is flushed immediately, especially important for Enter key
        if let Err(e) = self.writer.flush() {
            eprintln!("Failed to flush terminal: {e}");
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ctrl_c() -> KeyEvent {
        KeyEvent::new(KeyCode::Char('c'), KeyModifiers::CONTROL)
    }

    fn wait_until_finished(running: &RunningCommand) {
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !running.is_finished() {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }
    }

    #[test]
    fn test_running_command_ctrl_c_cancels_and_keeps_the_window_open() {
        let commands = [Command::Raw("sleep 10".to_string())];
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);

        // Give it a brief moment to spawn
        std::thread::sleep(std::time::Duration::from_millis(100));
        assert!(!running.is_finished());

        // Ctrl+C cancels the command, but the window stays to show the result
        assert!(!running.handle_key_event(&ctrl_c()));
        wait_until_finished(&running);
        let screen = running.screen(Size {
            width: 80,
            height: 24,
        });
        assert!(screen.contents().contains("Failed!"));
    }

    #[test]
    fn test_running_command_nested_process_cancellation() {
        let commands = [Command::Raw("sh -c 'sleep 30'".to_string())];
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);

        std::thread::sleep(std::time::Duration::from_millis(100));
        assert!(!running.is_finished());

        assert!(!running.handle_key_event(&ctrl_c()));
        wait_until_finished(&running);
    }

    #[test]
    fn test_running_command_ctrl_c_escalates_past_ignored_signals() {
        let commands = [Command::Raw("trap '' INT HUP TERM; sleep 30".to_string())];
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);

        std::thread::sleep(std::time::Duration::from_millis(100));
        assert!(!running.is_finished());
        assert!(running.cancel_hint().contains("Ctrl-C to cancel"));

        // SIGINT and SIGTERM are ignored: the command stays, and so does the window
        for hint in ["to terminate", "to force stop"] {
            assert!(!running.handle_key_event(&ctrl_c()));
            std::thread::sleep(std::time::Duration::from_millis(200));
            assert!(!running.is_finished());
            assert!(running.cancel_hint().contains(hint));
        }

        // SIGKILL cannot be ignored
        assert!(!running.handle_key_event(&ctrl_c()));
        wait_until_finished(&running);
    }

    #[test]
    fn test_running_command_forwards_repeated_esc_to_the_program() {
        let commands = [Command::Raw(
            "stty -icanon -echo min 2 time 0; printf 'ready\\n'; od -An -tx1 -N2".to_string(),
        )];
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);
        let size = Size {
            width: 80,
            height: 24,
        };

        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !running.screen(size).contents().contains("ready") {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }

        // Two presses, as people do in vim: neither closes the window or stops the command
        let esc = KeyEvent::new(KeyCode::Esc, KeyModifiers::NONE);
        assert!(!running.handle_key_event(&esc));
        assert!(!running.handle_key_event(&esc));

        wait_until_finished(&running);
        let contents = running.screen(size).contents();
        assert!(contents.contains("1b 1b"), "{contents}");
        assert!(contents.contains("Done!"), "{contents}");
    }

    #[test]
    fn test_only_esrch_means_the_process_group_is_gone() {
        assert!(process_group_alive(Ok(())));
        // All that is left belongs to another user: it is not gone.
        assert!(process_group_alive(Err(Errno::EPERM)));
        assert!(!process_group_alive(Err(Errno::ESRCH)));
    }

    #[test]
    fn test_signal_group_ignores_a_finished_process() {
        let commands = [Command::Raw("exit 0".to_string())];
        let refs: Vec<&Command> = commands.iter().collect();
        let running = RunningCommand::new(&refs);
        wait_until_finished(&running);

        let pid = running.child_pid.load(Ordering::Acquire);
        assert_eq!(RunningCommand::signal_group(pid, Signal::SIGTERM), None);
    }

    #[test]
    fn test_cancel_hint_shows_why_the_command_was_not_stopped() {
        let commands = [Command::Raw("exit 0".to_string())];
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);

        running.cancel_error = Some(Errno::EPERM.desc());
        let hint = running.cancel_hint();
        assert!(
            hint.contains("Not stopped: Operation not permitted"),
            "{hint}"
        );
        assert!(hint.contains("Ctrl-C to retry"), "{hint}");
    }

    #[test]
    fn test_running_command_any_key_closes_when_finished() {
        let commands = [Command::Raw("exit 0".to_string())];
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);

        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !running.is_finished() {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }

        // Screen output should have success indicator
        let screen = running.screen(Size {
            width: 80,
            height: 24,
        });
        assert!(screen
            .contents()
            .contains("Done! Press any key to close . . ."));

        // Any key should close the window, once the result has been up
        std::thread::sleep(RESULT_KEY_PAUSE);
        let key_a = KeyEvent::new(KeyCode::Char('a'), KeyModifiers::NONE);
        assert!(running.handle_key_event(&key_a));
        let esc = KeyEvent::new(KeyCode::Esc, KeyModifiers::NONE);
        assert!(running.handle_key_event(&esc));
    }

    /// A finished command whose result was drawn at the instant returned.
    fn drawn_result() -> (RunningCommand, Instant) {
        let command = Command::Raw("exit 0".to_string());
        let mut running = RunningCommand::new(&[&command]);
        wait_until_finished(&running);
        let drawn = Instant::now();
        running.result_quiet_since = Some(drawn);
        (running, drawn)
    }

    #[test]
    fn test_result_not_yet_drawn_stays_open_and_starts_no_pause() {
        let (mut running, drawn) = drawn_result();
        running.result_quiet_since = None;
        assert!(!running.key_closes_result(drawn + RESULT_KEY_PAUSE * 10));
        assert_eq!(running.result_quiet_since, None);
    }

    #[test]
    fn test_result_closes_at_exactly_the_pause() {
        let (mut running, drawn) = drawn_result();
        let just_under = RESULT_KEY_PAUSE - Duration::from_nanos(1);
        assert!(!running.key_closes_result(drawn + just_under));

        running.result_quiet_since = Some(drawn);
        assert!(running.key_closes_result(drawn + RESULT_KEY_PAUSE));
    }

    #[test]
    fn test_key_too_soon_restarts_the_pause() {
        let (mut running, drawn) = drawn_result();
        let just_under = RESULT_KEY_PAUSE - Duration::from_nanos(1);
        let mut last_key = drawn;
        for _ in 0..4 {
            last_key += just_under;
            assert!(!running.key_closes_result(last_key));
            assert_eq!(running.result_quiet_since, Some(last_key));
        }

        // Each key counts from the one before it, not from the result
        assert!(last_key - drawn > RESULT_KEY_PAUSE);
        assert!(!running.key_closes_result(last_key + just_under));
        last_key += just_under;
        assert!(running.key_closes_result(last_key + RESULT_KEY_PAUSE));
    }

    #[test]
    fn test_key_event_honours_the_pause() {
        let (mut running, drawn) = drawn_result();
        // Later than any clock reading this test can take
        running.result_quiet_since = Some(drawn + Duration::from_secs(3600));
        let key = KeyEvent::new(KeyCode::Char('x'), KeyModifiers::NONE);
        assert!(!running.handle_key_event(&key));
    }

    #[test]
    fn test_running_command_failure_completion_indicator() {
        let commands = [Command::Raw("exit 1".to_string())];
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);

        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !running.is_finished() {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }

        let screen = running.screen(Size {
            width: 80,
            height: 24,
        });
        assert!(screen
            .contents()
            .contains("Failed! Press any key to close . . ."));
    }

    #[test]
    fn test_running_command_invalid_choice_indicator() {
        let commands = [Command::Raw("exit 64".to_string())];
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);

        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !running.is_finished() {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }

        let screen = running.screen(Size {
            width: 80,
            height: 24,
        });
        assert!(screen
            .contents()
            .contains("Invalid! Press any key to close . . ."));
    }

    #[test]
    fn test_running_command_retry_after_invalid_choice_succeeds() {
        let commands = [Command::Raw(
            "printf 'Invalid choice. Please try again.\\nOption 1 selected.\\nInstallation complete.\\n'; exit 0".to_string(),
        )];
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);

        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !running.is_finished() {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }

        let screen = running.screen(Size {
            width: 80,
            height: 24,
        });
        assert!(screen
            .contents()
            .contains("Done! Press any key to close . . ."));
        assert!(!screen
            .contents()
            .contains("Invalid! Press any key to close . . ."));
    }

    #[test]
    fn test_tool_error_mentioning_invalid_reports_failure() {
        let contents = finished_contents(&[Command::Raw(
            "printf \"tar: invalid option -- 'q'\\n\"; exit 2".to_string(),
        )]);
        assert!(contents.contains("Failed! Press any key to close . . ."));
        assert!(!contents.contains("Invalid! Press any key to close . . ."));
    }

    #[test]
    fn test_running_command_unrelated_invalid_in_output_fails_normally() {
        let commands = [Command::Raw(
            "printf 'checking for invalid options...\\nerror: file not found\\n'; exit 1"
                .to_string(),
        )];
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);

        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !running.is_finished() {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }

        let screen = running.screen(Size {
            width: 80,
            height: 24,
        });
        assert!(screen
            .contents()
            .contains("Failed! Press any key to close . . ."));
        assert!(!screen
            .contents()
            .contains("Invalid! Press any key to close . . ."));
    }

    fn finished_contents(commands: &[Command]) -> String {
        let refs: Vec<&Command> = commands.iter().collect();
        let mut running = RunningCommand::new(&refs);
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !running.is_finished() {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }
        running
            .screen(Size {
                width: 80,
                height: 24,
            })
            .contents()
    }

    #[test]
    fn test_batch_with_failed_command_reports_failure() {
        let contents = finished_contents(&[
            Command::Raw("echo first; exit 3".to_string()),
            Command::Raw("echo second".to_string()),
        ]);
        // The batch keeps going after a failure, but is not reported as done.
        assert!(contents.contains("second"));
        assert!(contents.contains("Failed! Press any key to close . . ."));
    }

    #[test]
    fn test_batch_of_successful_commands_reports_done() {
        let contents = finished_contents(&[
            Command::Raw("true".to_string()),
            Command::Raw("echo ok".to_string()),
        ]);
        assert!(contents.contains("Done! Press any key to close . . ."));
    }

    #[test]
    fn test_narrow_terminal_does_not_reach_the_parser_with_an_empty_screen() {
        use crate::{float::Float, theme::Theme};
        use ratatui::{backend::TestBackend, Terminal};
        for output in ["echo hello", "printf '漢字\\n'"] {
            for width in 4..=12 {
                let command = Command::Raw(output.to_string());
                let running = RunningCommand::new(&[&command]);
                wait_until_finished(&running);
                let mut float = Float::new(Box::new(running), 75, 95).with_horizontal_inset(3);
                let mut terminal = Terminal::new(TestBackend::new(width, 24)).unwrap();
                terminal
                    .draw(|frame| float.draw(frame, frame.area(), &Theme::Default))
                    .unwrap();
            }
        }
    }

    #[test]
    fn test_default_output_takes_the_theme_colours_and_coloured_output_stays() {
        use crate::{float::Float, theme::Theme};
        use ratatui::{backend::TestBackend, Terminal};
        let theme = Theme::Default;
        let command = Command::Raw("printf '\\033[41mX\\033[0m plain\\n'".to_string());
        let running = RunningCommand::new(&[&command]);
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !running.is_finished() {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }
        let mut float = Float::new(Box::new(running), 75, 95).with_horizontal_inset(3);
        let mut terminal = Terminal::new(TestBackend::new(80, 24)).unwrap();
        terminal
            .draw(|frame| float.draw(frame, frame.area(), &theme))
            .unwrap();
        let buffer = terminal.backend().buffer();
        let find = |symbol: &str| buffer.content.iter().find(|cell| cell.symbol() == symbol);
        assert_ne!(find("X").unwrap().bg, theme.bg());
        let plain = find("p").unwrap();
        assert_eq!(plain.bg, theme.bg());
        assert_eq!(plain.fg, theme.cmd_color());
        assert!(Rect::new(15, 5, 50, 14)
            .positions()
            .all(|position| buffer[position].bg != Color::Reset));
    }

    #[test]
    fn test_invalid_choice_status_reports_invalid_without_script_message() {
        let contents = finished_contents(&[
            Command::Raw("printf 'Enter your choice [1-2]: 4\\n'; exit 64".to_string()),
            Command::Raw("echo next".to_string()),
        ]);
        assert!(contents.contains("next"));
        assert!(contents.contains("Invalid! Press any key to close . . ."));
        assert_eq!(contents.to_ascii_lowercase().matches("invalid").count(), 1);
    }
}

use crate::{float::FloatContent, theme::Theme};
use linutil_core::Command;
use oneshot::{channel, Receiver};
use portable_pty::{
    ChildKiller, CommandBuilder, ExitStatus, MasterPty, NativePtySystem, PtySize, PtySystem,
};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, KeyModifiers, MouseEvent, MouseEventKind},
    prelude::*,
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
    poll::{poll, PollFd, PollFlags},
    sys::signal::{kill, Signal},
    unistd::{getsid, Pid},
};

#[cfg(unix)]
use std::os::fd::{AsFd, BorrowedFd};

#[derive(Default)]
struct StartupCancellation {
    pending: usize,
    error: Option<&'static str>,
}

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
    /// Serializes PID publication with cancellation requested during startup.
    startup_cancellation: Arc<Mutex<StartupCancellation>>,
    /// Number of times kill_child has been invoked
    kill_count: usize,
    menu_consumed: usize,
    menu_back: bool,
    /// Why the last kill_child could not signal every process
    cancel_error: Option<&'static str>,
    /// A join handle for the thread that reads command output and sends it to the main thread
    reader_thread: Option<JoinHandle<()>>,
    reader_stop: Arc<AtomicBool>,
    /// First observation of the script leader exiting.
    leader_done_at: OnceLock<Instant>,
    /// Set once the process group is gone: its number can be reused after that.
    group_gone: AtomicBool,
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
    /// Whether the last rendered result warned about lingering work.
    result_background: Option<bool>,
}

/// How long keys must pause before one can close a result: long enough that
/// the key is a reaction to it, not one typed ahead or a held key repeating.
pub(crate) const RESULT_KEY_PAUSE: Duration = Duration::from_millis(300);

const LINGER_LIMIT: Duration = Duration::from_secs(2);

/// Why Ctrl-C cannot stop what only holds the terminal, from its own session.
const OTHER_SESSION: &str = "it runs in another session";

impl FloatContent for RunningCommand {
    fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &Theme) {
        // Define the block for the terminal display
        let block = if !self.is_finished() {
            // Display a block indicating the command is running
            crate::dashboard::block(
                Line::styled(
                    " Running Command ",
                    Style::default().fg(theme.tab_color()).bold(),
                )
                .centered(),
                theme,
                true,
            )
            .title_style(Style::default())
            .title_bottom(
                Line::styled(
                    self.cancel_hint(),
                    Style::default().fg(theme.unfocused_color()),
                )
                .centered(),
            )
        } else {
            // Display a block with the command's exit status
            let is_invalid = self.check_invalid_choice();
            let background = self.background_work_remains();
            let (title_line, border_color) = if background {
                (
                    Line::styled(
                        " Script ended; background work remains ",
                        Style::default().fg(Color::Yellow).bold(),
                    ),
                    Color::Yellow,
                )
            } else if self.get_exit_status().success() && !is_invalid {
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

            let log_path = if background {
                Line::styled(
                    self.background_hint(),
                    Style::default().fg(theme.unfocused_color()),
                )
            } else if let Some(log_path) = &self.log_path {
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

            crate::dashboard::block(title_line.centered(), theme, true)
                .title_style(Style::default())
                .border_style(Style::default().fg(border_color).bold())
                .title_bottom(log_path.centered())
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
        if key.code == KeyCode::Esc && (self.menu_waiting() || self.menu_back) {
            self.menu_back = true;
            self.kill_child();
            return self.should_close();
        }
        if self.menu_back && self.should_close() {
            return true;
        }
        if self.is_finished() {
            match key.code {
                KeyCode::Char('c' | 'C') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                    if self.background_work_remains() {
                        self.kill_child();
                    }
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
                _ if self.background_work_remains() => {
                    return matches!(key.code, KeyCode::Char('d' | 'D'))
                        && key.modifiers.contains(KeyModifiers::CONTROL)
                        && self.key_closes_result(Instant::now());
                }
                _ => return self.key_closes_result(Instant::now()),
            }
        }

        if matches!(key.code, KeyCode::Enter)
            || (key.modifiers.contains(KeyModifiers::CONTROL)
                && matches!(key.code, KeyCode::Char('j' | 'm' | 'd')))
        {
            // Do not advertise a stale menu while the script processes input.
            self.menu_consumed = self.buffer.lock().unwrap().len();
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
        if !self.leader_exited() {
            return false;
        }
        let done = self.leader_done_at.get_or_init(Instant::now);
        !self.background_work_remains() || done.elapsed() >= LINGER_LIMIT
    }

    fn should_close(&self) -> bool {
        self.menu_back && self.leader_exited() && !self.background_work_remains()
    }

    fn result_pending(&self) -> bool {
        self.is_finished()
            && (self.result_quiet_since.is_none()
                || self.result_background != Some(self.background_work_remains()))
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
            // A separate shell isolates `exit` and preserves `set -e`: putting
            // a subshell directly before `||` disables errexit inside it.
            Command::Raw(prompt) => {
                let quoted_prompt = prompt.replace('\'', "'\\''");
                script.push_str(&format!("sh -c '{quoted_prompt}' || linutil_failed=$?\n"))
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

/// Linux reports a terminal with no writers left as EIO, not as end of file.
#[cfg(unix)]
fn terminal_closed(error: &std::io::Error) -> bool {
    error.raw_os_error() == Some(Errno::EIO as i32)
}

/// The bullet before "Done!"/"Failed!". The Linux console font has no `●`.
fn status_marker() -> &'static str {
    if crate::dashboard::is_basic_terminal() {
        "*"
    } else {
        "●"
    }
}

impl RunningCommand {
    fn leader_exited(&self) -> bool {
        self.command_thread
            .as_ref()
            .is_none_or(JoinHandle::is_finished)
    }

    /// Remaining work is tracked separately from the leader's result so that
    /// a timeout never makes cancellation errors look like a successful stop.
    fn background_work_remains(&self) -> bool {
        #[cfg(unix)]
        if !self.group_gone.load(Ordering::Acquire) {
            let pid = self.child_pid.load(Ordering::Acquire);
            if pid != 0 {
                if process_group_alive(kill(Pid::from_raw(-(pid as i32)), None)) {
                    return true;
                }
                self.group_gone.store(true, Ordering::Release);
            }
        }
        !self
            .reader_thread
            .as_ref()
            .is_none_or(JoinHandle::is_finished)
    }

    pub fn new(commands: &[&Command]) -> Self {
        Self::new_with_start_hook(commands, || {})
    }

    fn new_with_start_hook(
        commands: &[&Command],
        before_pid_publication: impl FnOnce() + Send + 'static,
    ) -> Self {
        let pty_system = NativePtySystem::default();

        // Build the command based on the provided Command enum variant
        let mut cmd: CommandBuilder = CommandBuilder::new("sh");
        cmd.arg("-c");

        // Set environment variables needed for interactive TUI tools like gum
        cmd.env("LINUTIL_MENU_PROTOCOL", "1");
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
        let startup_cancellation = Arc::new(Mutex::new(StartupCancellation::default()));
        let startup_clone = Arc::clone(&startup_cancellation);
        let (tx, rx) = channel();
        // Thread waiting for the child to complete
        let command_handle = std::thread::spawn(move || {
            let mut child = pair.slave.spawn_command(cmd).unwrap();
            let mut killer = child.clone_killer();
            before_pid_publication();
            {
                let mut startup = startup_clone.lock().unwrap();
                if let Some(pid) = child.process_id() {
                    child_pid_clone.store(pid, Ordering::Release);
                    // A request either lands in this queue or sees the published
                    // PID under the same lock. There is no unprotected handoff.
                    for attempt in 0..startup.pending {
                        #[cfg(unix)]
                        {
                            let signal = Self::cancellation_signal(attempt);
                            startup.error = Self::signal_ids(pid, signal, false, false)
                                .or(Self::kill_session_processes(pid, signal))
                                .map(Errno::desc);
                            if attempt >= 2 {
                                let _ = killer.kill();
                            }
                        }
                        #[cfg(not(unix))]
                        let _ = killer.kill();
                    }
                }
                startup.pending = 0;
            }
            TERMINAL_UPDATED.store(true, Ordering::Release);
            let _ = tx.send(killer);
            child.wait().unwrap()
        });

        // Own the reader descriptor, so polling it stays safe even when the
        // command window is dropped. No nonblocking flags affect the writer.
        #[cfg(unix)]
        let mut reader = {
            // SAFETY: pair.master owns this descriptor throughout the clone.
            let fd = unsafe { BorrowedFd::borrow_raw(pair.master.as_raw_fd().unwrap()) };
            File::from(fd.try_clone_to_owned().unwrap())
        };
        #[cfg(not(unix))]
        let mut reader = pair.master.try_clone_reader().unwrap();
        let reader_stop = Arc::new(AtomicBool::new(false));

        // A buffer, shared between the thread that reads the command output, and the main tread.
        // The main thread only reads the contents
        let command_buffer: Arc<Mutex<Vec<u8>>> = Arc::new(Mutex::new(Vec::new()));
        TERMINAL_UPDATED.store(true, Ordering::Release);
        let reader_handle = {
            // Arc is just a reference, so we can create an owned copy without any problem
            let command_buffer = command_buffer.clone();
            let reader_stop = reader_stop.clone();
            // The closure below moves all variables used into it, so we can no longer use them,
            // that's why command_buffer.clone(), because we need to use command_buffer later
            std::thread::spawn(move || {
                let mut buf = [0u8; 8192];
                while !reader_stop.load(Ordering::Acquire) {
                    #[cfg(unix)]
                    {
                        let mut fds = [PollFd::new(reader.as_fd(), PollFlags::POLLIN)];
                        match poll(&mut fds, 100u16) {
                            Ok(0) | Err(Errno::EINTR) => continue,
                            Err(_) => break,
                            Ok(_) => {}
                        }
                    }
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
                        #[cfg(unix)]
                        Err(e) if terminal_closed(&e) => break,
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
            startup_cancellation,
            kill_count: 0,
            menu_consumed: 0,
            menu_back: false,
            cancel_error: None,
            reader_thread: Some(reader_handle),
            reader_stop,
            leader_done_at: OnceLock::new(),
            group_gone: AtomicBool::new(false),
            pty_master: pair.master,
            writer,
            status: None,
            log_path: None,
            scroll_offset: 0,
            result_quiet_since: None,
            result_background: None,
        }
    }

    fn menu_waiting(&self) -> bool {
        if self.kill_count != 0 || self.leader_exited() {
            return false;
        }
        let buffer = self.buffer.lock().unwrap();
        let pending = &buffer[self.menu_consumed.min(buffer.len())..];
        let menu = b"\x1b]777;linutil;menu\x07";
        let running = b"\x1b]777;linutil;running\x07";
        let last_menu = pending.windows(menu.len()).rposition(|w| w == menu);
        let last_running = pending.windows(running.len()).rposition(|w| w == running);
        last_menu.is_some_and(|menu| last_running.is_none_or(|running| menu > running))
    }

    /// The footer while a command runs: what Ctrl-C does next, or why it failed.
    fn cancel_hint(&self) -> String {
        let startup_error = self.startup_cancellation.lock().unwrap().error;
        if let Some(error) = self.cancel_error.or(startup_error) {
            return format!(" Not stopped: {error} · Ctrl-C to retry ");
        }
        if self.menu_waiting() {
            return " Esc to go back ".to_string();
        }
        match self.kill_count {
            0 => " Ctrl+C to Abort ",
            1 => " Cancelling · Ctrl-C to terminate ",
            2 => " Terminating · Ctrl-C to force stop ",
            _ => " Force stop sent · Ctrl-C to retry ",
        }
        .to_string()
    }

    /// The footer while background work remains, short enough for the narrowest
    /// dashboard. The title and the output already say that work may continue.
    fn background_hint(&self) -> String {
        let hint = match self.cancel_error {
            Some(error) => format!("Not stopped: {error}"),
            None => self.cancel_hint().trim().to_string(),
        };
        format!(" {hint} · Ctrl-D to leave ")
    }

    /// Only the exit status counts: the output may mention "invalid" for
    /// unrelated reasons, e.g. a failing tool's "invalid option".
    fn check_invalid_choice(&mut self) -> bool {
        self.get_exit_status().exit_code() == INVALID_CHOICE_STATUS
    }

    /// A key can arrive before the frame showing the result, and queued or held
    /// keys right after it. None of them may close a result nobody could read.
    fn key_closes_result(&mut self, now: Instant) -> bool {
        // The frame on screen may be a warning about work that has since ended.
        if self.result_pending() {
            return false;
        }
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
            let background = self.background_work_remains();
            let (color, message) = if background {
                (
                    "33",
                    format!(
                        "Script exited with status {}. Background work remains.\r\n\
                         Ctrl-C to stop it; Ctrl-D to leave (work may continue).",
                        self.get_exit_status().exit_code()
                    ),
                )
            } else {
                (color, format!("{status} Press any key to close . . ."))
            };
            let msg = format!(
                "\r\n\x1b[1;{color}m{} {message}\x1b[0m\r\n",
                status_marker()
            );
            if let Ok(mut mutex) = self.buffer.lock() {
                mutex.extend_from_slice(msg.as_bytes());
            }
            self.result_quiet_since = Some(Instant::now());
            self.result_background = Some(background);
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
        self.scroll_offset = parser.screen().scrollback();
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
        if self.leader_exited() && !self.background_work_remains() {
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

        let pid = {
            let mut startup = self.startup_cancellation.lock().unwrap();
            let pid = self.child_pid.load(Ordering::Acquire);
            if pid == 0 {
                startup.pending += 1;
                self.kill_count += 1;
                return;
            }
            startup.error = None;
            pid
        };

        // What is left holds only the terminal, from a session of its own. The
        // command's IDs cannot reach it and may now belong to something else.
        #[cfg(unix)]
        if pid != 0
            && self.group_gone.load(Ordering::Acquire)
            && Self::session_processes(pid).is_empty()
        {
            self.cancel_error = Some(OTHER_SESSION);
            return;
        }

        #[cfg(unix)]
        {
            let signal = Self::cancellation_signal(self.kill_count);
            let error = self
                .signal_group(pid, signal)
                .or(Self::kill_session_processes(pid, signal));
            if self.kill_count >= 2 && !self.leader_exited() {
                if let Some(killer) = &mut self.killer {
                    let _ = killer.kill();
                }
            }
            self.cancel_error = error.map(Errno::desc);
        }

        #[cfg(not(unix))]
        if let Some(killer) = &mut self.killer {
            let _ = killer.kill();
        }

        self.kill_count += 1;
    }

    #[cfg(unix)]
    fn cancellation_signal(attempt: usize) -> Signal {
        match attempt {
            0 => Signal::SIGINT,
            1 => Signal::SIGTERM,
            _ => Signal::SIGKILL,
        }
    }

    /// Signal the process group and its leader. A process that has already
    /// exited is not an error.
    #[cfg(unix)]
    fn signal_group(&self, pid: u32, signal: Signal) -> Option<Errno> {
        Self::signal_ids(
            pid,
            signal,
            self.group_gone.load(Ordering::Acquire),
            self.leader_exited(),
        )
    }

    #[cfg(unix)]
    fn signal_ids(
        pid: u32,
        signal: Signal,
        group_gone: bool,
        leader_exited: bool,
    ) -> Option<Errno> {
        let group = if group_gone {
            Ok(())
        } else {
            kill(Pid::from_raw(-(pid as i32)), signal)
        };
        let leader = if leader_exited {
            Ok(())
        } else {
            kill(Pid::from_raw(pid as i32), signal)
        };
        [group, leader]
            .into_iter()
            .filter_map(|result| result.err())
            .find(|error| *error != Errno::ESRCH)
    }

    /// The processes of a session, other than its leader.
    #[cfg(unix)]
    fn session_processes(session_pid: u32) -> Vec<Pid> {
        let Ok(entries) = std::fs::read_dir("/proc") else {
            return Vec::new();
        };
        entries
            .flatten()
            .filter_map(|entry| entry.file_name().to_str()?.parse::<i32>().ok())
            .filter(|&p| p > 1 && p != session_pid as i32)
            .map(Pid::from_raw)
            .filter(|&p| getsid(Some(p)).is_ok_and(|sid| sid.as_raw() == session_pid as i32))
            .collect()
    }

    /// Signal the rest of the session. A permission error is returned: a group
    /// signal that reached some processes succeeds without saying so.
    #[cfg(unix)]
    fn kill_session_processes(session_pid: u32, signal: Signal) -> Option<Errno> {
        let mut denied = None;
        for process in Self::session_processes(session_pid) {
            if kill(process, signal) == Err(Errno::EPERM) {
                denied = Some(Errno::EPERM);
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

impl Drop for RunningCommand {
    fn drop(&mut self) {
        self.reader_stop.store(true, Ordering::Release);
        // Unix readers poll with a timeout, so a child keeping the PTY open
        // cannot strand a reader thread after the user leaves the window.
        #[cfg(unix)]
        if let Some(reader) = self.reader_thread.take() {
            let _ = reader.join();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ctrl_c() -> KeyEvent {
        KeyEvent::new(KeyCode::Char('c'), KeyModifiers::CONTROL)
    }

    fn ctrl_d() -> KeyEvent {
        KeyEvent::new(KeyCode::Char('d'), KeyModifiers::CONTROL)
    }

    fn wait_until_finished(running: &RunningCommand) {
        let deadline = std::time::Instant::now() + std::time::Duration::from_secs(5);
        while !running.is_finished() {
            assert!(std::time::Instant::now() < deadline);
            std::thread::sleep(std::time::Duration::from_millis(20));
        }
    }

    #[test]
    fn cancellation_before_pid_publication_is_replayed() {
        for presses in [1, 3] {
            let (ready_tx, ready_rx) = std::sync::mpsc::channel();
            let (release_tx, release_rx) = std::sync::mpsc::channel();
            let command = Command::Raw("sleep 60".into());
            let mut running = RunningCommand::new_with_start_hook(&[&command], move || {
                ready_tx.send(()).unwrap();
                release_rx.recv().unwrap();
            });
            ready_rx.recv_timeout(Duration::from_secs(5)).unwrap();
            assert_eq!(running.child_pid.load(Ordering::Acquire), 0);
            for _ in 0..presses {
                assert!(!running.handle_key_event(&ctrl_c()));
            }
            let queued = running.startup_cancellation.lock().unwrap().pending;
            release_tx.send(()).unwrap();
            let deadline = Instant::now() + Duration::from_secs(5);
            while !running.is_finished() && Instant::now() < deadline {
                std::thread::sleep(Duration::from_millis(5));
            }
            let stopped = running.is_finished();
            if !stopped {
                for _ in 0..3 {
                    running.kill_child();
                }
                wait_until_finished(&running);
            }
            assert_eq!(queued, presses);
            assert_eq!(running.kill_count, presses);
            assert!(stopped, "Cancellation was lost during startup");
            assert!(!running.get_exit_status().success());
        }
    }

    #[test]
    fn menu_submission_switches_to_abort_and_preserves_escape_passthrough() {
        let command = Command::Raw(format!(
            ". '{}/../core/tabs/common-script.sh'; readMenuChoice choice; printf 'selected:%s\\n' \"$choice\"; stty -icanon -echo min 1 time 0; printf 'ready\\n'; od -An -tx1 -N1",
            env!("CARGO_MANIFEST_DIR")
        ));
        let mut running = RunningCommand::new(&[&command]);
        let deadline = Instant::now() + Duration::from_secs(5);
        while !running.menu_waiting() {
            assert!(Instant::now() < deadline);
            std::thread::sleep(Duration::from_millis(10));
        }
        assert_eq!(running.cancel_hint().trim(), "Esc to go back");
        running.handle_key_event(&KeyEvent::new(KeyCode::Char('1'), KeyModifiers::NONE));
        assert!(running.menu_waiting());
        running.handle_key_event(&KeyEvent::new(KeyCode::Enter, KeyModifiers::NONE));
        assert_eq!(running.cancel_hint().trim(), "Ctrl+C to Abort");
        let size = Size {
            width: 80,
            height: 24,
        };
        while !running.screen(size).contents().contains("ready") {
            assert!(Instant::now() < deadline);
            std::thread::sleep(Duration::from_millis(10));
        }
        assert!(!running.handle_key_event(&KeyEvent::new(KeyCode::Esc, KeyModifiers::NONE)));
        wait_until_finished(&running);
        let output = running.screen(size).contents();
        assert!(output.contains("selected:1"), "{output}");
        assert!(output.contains("1b"), "{output}");
        assert!(!output.contains("777;linutil"), "{output}");
        assert!(!running.should_close());
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
        assert!(running.cancel_hint().contains("Ctrl+C to Abort"));

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
        assert_eq!(running.signal_group(pid, Signal::SIGTERM), None);
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
        running.result_background = Some(false);
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

    const SCREEN: Size = Size {
        width: 80,
        height: 24,
    };

    fn wait_until(mut condition: impl FnMut() -> bool) {
        let deadline = Instant::now() + Duration::from_secs(5);
        while !condition() {
            assert!(Instant::now() < deadline, "Timed out");
            std::thread::sleep(Duration::from_millis(10));
        }
    }

    /// A background process started by a test. It is stopped when the test ends,
    /// even on a failed assertion, and its unique `sleep` length makes sure
    /// that nothing else is ever signalled.
    struct OwnedProcess {
        marker: &'static str,
        pid_file: std::path::PathBuf,
    }

    impl OwnedProcess {
        fn new(marker: &'static str) -> Self {
            let name = format!("linutil-test-{}-{marker}", std::process::id());
            Self {
                marker,
                pid_file: std::env::temp_dir().join(name),
            }
        }

        /// The script line that leaves this process behind. It ignores hangup,
        /// or the terminal's hangup at the end of the script would stop it.
        fn script(&self, launcher: &str) -> String {
            format!(
                "trap '' HUP; {launcher} sleep {} & echo $! > '{}'",
                self.marker,
                self.pid_file.display()
            )
        }

        fn pid(&self) -> Option<Pid> {
            let pid = std::fs::read_to_string(&self.pid_file).ok()?;
            Some(Pid::from_raw(pid.trim().parse().ok()?))
        }

        fn is_running(&self) -> bool {
            self.pid().is_some_and(|pid| {
                std::fs::read(format!("/proc/{pid}/cmdline"))
                    .is_ok_and(|cmdline| String::from_utf8_lossy(&cmdline).contains(self.marker))
            })
        }

        fn stop(&self) {
            if self.is_running() {
                let _ = kill(self.pid().unwrap(), Signal::SIGKILL);
            }
        }
    }

    impl Drop for OwnedProcess {
        fn drop(&mut self) {
            self.stop();
            let _ = std::fs::remove_file(&self.pid_file);
        }
    }

    /// Runs a script that leaves work behind, until the script itself has ended.
    fn start_lingering(script: String) -> RunningCommand {
        let command = Command::Raw(script);
        let running = RunningCommand::new(&[&command]);
        wait_until(|| running.leader_exited());
        running
    }

    /// One test waits for the real grace period. The others skip it.
    fn end_grace_period(running: &RunningCommand) {
        running
            .leader_done_at
            .set(Instant::now() - LINGER_LIMIT)
            .unwrap();
    }

    #[test]
    fn test_lingering_work_gets_a_warning_and_only_ctrl_d_leaves() {
        let fixture = OwnedProcess::new("61.0731");
        let mut running = start_lingering(format!("{}; exit 7", fixture.script("")));

        // The window holds on to the script for the grace period only
        let started = Instant::now();
        assert!(!running.is_finished());
        wait_until(|| running.is_finished());
        assert!(started.elapsed() >= LINGER_LIMIT);
        assert!(fixture.is_running());

        // Nothing leaves before the warning has been drawn
        assert!(running.result_pending());
        assert!(!running.handle_key_event(&ctrl_d()));

        let contents = running.screen(SCREEN).contents();
        assert!(contents.contains("status 7"), "{contents}");
        assert!(contents.contains("Background work remains"), "{contents}");
        assert!(!contents.contains("Failed!"), "{contents}");
        assert!(!contents.contains("Press any key"), "{contents}");
        assert!(!running.result_pending());

        // Ordinary keys never leave, however late they come
        std::thread::sleep(RESULT_KEY_PAUSE);
        for code in [
            KeyCode::Esc,
            KeyCode::Enter,
            KeyCode::Char('q'),
            KeyCode::Char('d'),
        ] {
            assert!(!running.handle_key_event(&KeyEvent::new(code, KeyModifiers::NONE)));
        }

        // Ctrl-D follows the same pause as any key that closes a result
        running.result_quiet_since = Some(Instant::now() + Duration::from_secs(3600));
        assert!(!running.handle_key_event(&ctrl_d()));
        std::thread::sleep(RESULT_KEY_PAUSE);
        assert!(running.handle_key_event(&ctrl_d()));
        assert!(fixture.is_running());
    }

    #[test]
    fn test_ctrl_c_still_stops_lingering_work_after_the_grace_period() {
        let fixture = OwnedProcess::new("61.0732");
        let mut running = start_lingering(fixture.script(""));
        end_grace_period(&running);
        assert!(running.is_finished());
        assert!(running
            .screen(SCREEN)
            .contents()
            .contains("Background work remains"));

        // A background job of a non-interactive shell ignores SIGINT
        assert!(!running.handle_key_event(&ctrl_c()));
        assert!(running.cancel_hint().contains("to terminate"));
        assert!(!running.handle_key_event(&ctrl_c()));
        wait_until(|| !fixture.is_running());

        wait_until(|| !running.background_work_remains());
        assert!(running.result_pending());
        let contents = running.screen(SCREEN).contents();
        assert!(contents.contains("Done! Press any key"), "{contents}");
    }

    #[test]
    fn test_key_cannot_close_a_final_result_behind_an_old_warning() {
        let fixture = OwnedProcess::new("61.0733");
        let mut running = start_lingering(fixture.script(""));
        end_grace_period(&running);
        running.screen(SCREEN);
        assert_eq!(running.result_background, Some(true));

        // The warning has been up long enough for a key to close a result
        std::thread::sleep(RESULT_KEY_PAUSE);
        fixture.stop();
        wait_until(|| !running.background_work_remains());

        let key = KeyEvent::new(KeyCode::Char('x'), KeyModifiers::NONE);
        assert!(running.result_pending());
        assert!(!running.handle_key_event(&key));

        let contents = running.screen(SCREEN).contents();
        assert!(contents.contains("Background work remains"), "{contents}");
        assert!(contents.contains("Done! Press any key"), "{contents}");
        assert_eq!(running.result_background, Some(false));
        assert!(!running.result_pending());

        std::thread::sleep(RESULT_KEY_PAUSE);
        assert!(running.handle_key_event(&key));
    }

    #[test]
    fn test_leaving_releases_the_reader_and_leaves_a_hangup_proof_job_alone() {
        let fixture = OwnedProcess::new("61.0734");
        let mut running = start_lingering(fixture.script(""));
        end_grace_period(&running);
        running.screen(SCREEN);

        let buffer = Arc::downgrade(&running.buffer);
        drop(running);
        assert!(buffer.upgrade().is_none(), "The reader kept the buffer");

        // Closing the terminal sends its hangup at once
        std::thread::sleep(Duration::from_millis(200));
        assert!(fixture.is_running());
    }

    #[test]
    fn test_process_in_another_session_gets_a_warning_and_is_never_signalled() {
        let fixture = OwnedProcess::new("61.0735");
        let mut running = start_lingering(fixture.script("setsid"));
        end_grace_period(&running);

        // Only the terminal connects it to the command now
        wait_until(|| {
            fixture
                .pid()
                .is_some_and(|pid| getsid(Some(pid)) == Ok(pid))
        });
        wait_until(|| {
            running.background_work_remains();
            running.group_gone.load(Ordering::Acquire)
        });
        assert!(running.background_work_remains());
        assert!(running.is_finished());
        assert!(running
            .screen(SCREEN)
            .contents()
            .contains("Background work remains"));

        // The command's IDs are free and may be reused: Ctrl-C says so instead
        assert!(!running.handle_key_event(&ctrl_c()));
        assert_eq!(running.kill_count, 0);
        let hint = running.cancel_hint();
        assert!(hint.contains("Not stopped: it runs in another"), "{hint}");
        assert!(fixture.is_running());

        std::thread::sleep(RESULT_KEY_PAUSE);
        assert!(running.handle_key_event(&ctrl_d()));
        let buffer = Arc::downgrade(&running.buffer);
        drop(running);
        assert!(buffer.upgrade().is_none(), "The reader kept the buffer");
    }

    #[test]
    fn first_interrupt_reaches_a_background_process_in_another_group() {
        let fixture = OwnedProcess::new("61.0737");
        // Bash monitor mode starts the asynchronous job in its own process group
        // with SIGINT enabled, while retaining the PTY session.
        let script = format!(
            "bash -m -c \"trap '' HUP; sleep {} & echo \\$! > '{}'\"",
            fixture.marker,
            fixture.pid_file.display()
        );
        let mut running = start_lingering(script);
        wait_until(|| fixture.is_running());
        let pid = fixture.pid().unwrap();
        let leader = running.child_pid.load(Ordering::Acquire);
        assert_eq!(getsid(Some(pid)).unwrap().as_raw(), leader as i32);
        assert_eq!(nix::unistd::getpgid(Some(pid)), Ok(pid));
        wait_until(|| {
            running.background_work_remains();
            running.group_gone.load(Ordering::Acquire)
        });
        running.kill_child();
        assert_eq!(running.kill_count, 1);
        wait_until(|| !fixture.is_running());
    }

    #[test]
    fn scrolling_past_short_output_does_not_accumulate_offset() {
        let (mut running, _) = drawn_result();
        for _ in 0..5 {
            running.handle_key_event(&KeyEvent::new(KeyCode::PageUp, KeyModifiers::NONE));
        }
        running.screen(SCREEN);
        assert_eq!(running.scroll_offset, 0);
    }

    #[test]
    fn test_a_group_seen_gone_is_not_probed_again() {
        let (running, _) = drawn_result();
        assert!(!running.background_work_remains());
        assert!(running.group_gone.load(Ordering::Acquire));

        // This process's own group answers a probe, as a reused number would
        let reused = nix::unistd::getpgrp().as_raw() as u32;
        running.child_pid.store(reused, Ordering::Release);
        assert!(!running.background_work_remains());
    }

    #[test]
    fn test_refused_signal_stays_visible_on_the_warning() {
        use crate::{float::Float, theme::Theme};
        use ratatui::{backend::TestBackend, buffer::Cell, Terminal};

        let fixture = OwnedProcess::new("61.0736");
        let running = start_lingering(fixture.script(""));
        end_grace_period(&running);
        let mut float = Float::new(Box::new(running), 75, 95).with_horizontal_inset(3);

        // The narrowest dashboard. Needs no root: a refused signal only leaves this
        let mut terminal = Terminal::new(TestBackend::new(90, 25)).unwrap();
        for error in [Errno::EPERM.desc(), OTHER_SESSION] {
            float.content.cancel_error = Some(error);
            terminal
                .draw(|frame| float.draw(frame, frame.area(), &Theme::Default))
                .unwrap();
            let rendered: String = terminal
                .backend()
                .buffer()
                .content
                .iter()
                .map(Cell::symbol)
                .collect();
            assert!(rendered.contains(" Script ended; background work remains "));
            assert!(
                rendered.contains(&format!(" Not stopped: {error} ")),
                "{rendered}"
            );
            assert!(rendered.contains(" Ctrl-D to leave "), "{rendered}");
        }
    }

    #[test]
    fn test_only_eio_means_the_terminal_closed() {
        use std::io::Error;
        assert!(terminal_closed(&Error::from_raw_os_error(
            Errno::EIO as i32
        )));
        assert!(!terminal_closed(&Error::from_raw_os_error(
            Errno::EBADF as i32
        )));
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
    fn test_batch_preserves_inline_errexit() {
        let commands = [
            Command::Raw("set -e; false; printf 'continued\\n'".to_string()),
            Command::Raw("printf 'next\\n'".to_string()),
        ];
        let refs: Vec<&Command> = commands.iter().collect();
        let output = std::process::Command::new("sh")
            .args(["-c", &batch_script(&refs)])
            .output()
            .unwrap();
        assert_eq!(output.status.code(), Some(1));
        assert_eq!(output.stdout, b"next\n");
    }

    #[test]
    fn test_batch_preserves_inline_shell_quoting() {
        let command = Command::Raw(
            "value='quoted'; printf \"%s\\n\" \"it's $value\" \"$(printf substitution)\"\ncat <<'EOF'\n$literal `literal`\nEOF".to_string(),
        );
        let output = std::process::Command::new("sh")
            .args(["-c", &batch_script(&[&command])])
            .output()
            .unwrap();
        assert!(output.status.success());
        assert_eq!(
            output.stdout,
            b"it's quoted\nsubstitution\n$literal `literal`\n"
        );
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

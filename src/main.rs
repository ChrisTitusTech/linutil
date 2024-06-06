mod float;
mod list;
mod running_command;
mod theme;

use std::{
    io::{self, stdout},
    time::Duration,
};

use clap::Parser;
use crossterm::{
    cursor::RestorePosition,
    event::{self, DisableMouseCapture, Event, KeyCode, KeyEventKind, KeyModifiers},
    style::ResetColor,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    ExecutableCommand,
};
use list::CustomList;
use ratatui::{
    backend::{Backend, CrosstermBackend},
    Terminal,
};
use running_command::RunningCommand;
use theme::set_theme;

/// This is a binary :), Chris, change this to update the documentation on -h
#[derive(Debug, Parser)]
struct Args {
    /// Enable compatibility mode (disable icons and RGB colors)
    #[arg(short, long, default_value_t = false)]
    compat: bool,
}

fn main() -> std::io::Result<()> {
    let args = Args::parse();
    if args.compat {
        set_theme(0);
    }

    stdout().execute(EnterAlternateScreen)?;
    enable_raw_mode()?;
    let mut terminal = Terminal::new(CrosstermBackend::new(stdout()))?;
    terminal.clear()?;

    run(&mut terminal)?;

    // restore terminal
    disable_raw_mode()?;
    terminal.backend_mut().execute(LeaveAlternateScreen)?;
    terminal.backend_mut().execute(DisableMouseCapture)?;
    terminal.backend_mut().execute(ResetColor)?;
    terminal.backend_mut().execute(RestorePosition)?;
    terminal.show_cursor()?;
    Ok(())
}

fn run<B: Backend>(terminal: &mut Terminal<B>) -> io::Result<()> {
    let mut command_opt: Option<RunningCommand> = None;

    let mut custom_list = CustomList::new();
    loop {
        // If currently running a command, display the command window, else display only the list
        // Event read is blocking
        if event::poll(Duration::from_millis(10))? {
            // It's guaranteed that the `read()` won't block when the `poll()`
            // function returns `true`
            if let Event::Key(key) = event::read()? {
                // We are only interested in Press and Repeat events
                if key.kind == KeyEventKind::Press || key.kind == KeyEventKind::Repeat {
                    // Only process list inputs when a command is not running
                    if let None = command_opt {
                        if let Some(cmd) = custom_list.handle_key(key) {
                            command_opt = Some(RunningCommand::new(cmd));
                        }
                    }

                    // In the future we might want to add key handling for the running command, and
                    // we would put it here
                    match key.code {
                        KeyCode::Char('q') => return Ok(()),
                        KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                            if let Some(ref mut command) = command_opt {
                                command.kill_child();
                            }
                        }
                        KeyCode::Enter => {
                            if let Some(ref mut command) = command_opt {
                                if command.is_finished() {
                                    command_opt = None;
                                }
                            }
                        }
                        _ => (),
                    };
                }
            }
        }

        terminal
            .draw(|frame| {
                custom_list.draw(frame, frame.size());
                if let Some(ref mut command) = &mut command_opt {
                    command.draw(frame);
                }
            })
            .unwrap();
    }
}

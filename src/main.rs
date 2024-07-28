mod float;
mod list;
mod running_command;
pub mod state;
mod theme;

use std::{
    io::{self, stdout},
    time::Duration,
};

use clap::Parser;
use crossterm::{
    cursor::RestorePosition,
    event::{self, DisableMouseCapture, Event, KeyCode, KeyEventKind},
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
use state::AppState;
use theme::THEMES;

/// This is a binary :), Chris, change this to update the documentation on -h
#[derive(Debug, Parser)]
struct Args {
    /// Enable compatibility mode (disable icons and RGB colors)
    #[arg(short, long, default_value_t = false)]
    compat: bool,
}

fn main() -> std::io::Result<()> {
    let args = Args::parse();

    let theme = if args.compat {
        THEMES[0].clone()
    } else {
        THEMES[1].clone()
    };

    let state = AppState {
        theme,
    };

    stdout().execute(EnterAlternateScreen)?;
    enable_raw_mode()?;
    let mut terminal = Terminal::new(CrosstermBackend::new(stdout()))?;
    terminal.clear()?;

    run(&mut terminal, &state)?;

    // restore terminal
    disable_raw_mode()?;
    terminal.backend_mut().execute(LeaveAlternateScreen)?;
    terminal.backend_mut().execute(DisableMouseCapture)?;
    terminal.backend_mut().execute(ResetColor)?;
    terminal.backend_mut().execute(RestorePosition)?;
    terminal.show_cursor()?;
    Ok(())
}

fn run<B: Backend>(terminal: &mut Terminal<B>, state: &AppState) -> io::Result<()> {
    let mut command_opt: Option<RunningCommand> = None;

    let mut custom_list = CustomList::new();
    loop {
        // Always redraw
        terminal
            .draw(|frame| {
                custom_list.draw(frame, frame.size(), state);
                if let Some(ref mut command) = &mut command_opt {
                    command.draw(frame, state);
                }
            })
            .unwrap();

        // Wait for an event
        if !event::poll(Duration::from_millis(10))? {
            continue;
        }

        // It's guaranteed that the `read()` won't block when the `poll()`
        // function returns `true`
        if let Event::Key(key) = event::read()? {
            // We are only interested in Press and Repeat events
            if key.kind != KeyEventKind::Press && key.kind != KeyEventKind::Repeat {
                continue;
            }
            if let Some(ref mut command) = command_opt {
                if command.handle_key_event(&key) {
                    command_opt = None;
                }
            } else {
                if key.code == KeyCode::Char('q') {
                    return Ok(());
                }
                if let Some(cmd) = custom_list.handle_key(key) {
                    command_opt = Some(RunningCommand::new(cmd));
                }
            }
        }
    }
}

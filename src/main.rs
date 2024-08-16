mod float;
mod floating_text;
mod running_command;
pub mod state;
mod tabs;
mod theme;

use std::{
    io::{self, stdout},
    time::Duration,
};

use clap::Parser;
use crossterm::{
    cursor::RestorePosition,
    event::{self, DisableMouseCapture, Event, KeyEventKind},
    style::ResetColor,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    ExecutableCommand,
};
use include_dir::include_dir;
use ratatui::{
    backend::{Backend, CrosstermBackend},
    Terminal,
};
use state::AppState;
use tempdir::TempDir;
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
    let commands_dir = include_dir!("src/commands");
    let temp_dir: TempDir = TempDir::new("linutil_scripts").unwrap();
    commands_dir
        .extract(temp_dir.path())
        .expect("Failed to extract the saved directory");

    let mut state = AppState::new(theme, temp_dir.path().to_owned());

    stdout().execute(EnterAlternateScreen)?;
    enable_raw_mode()?;
    let mut terminal = Terminal::new(CrosstermBackend::new(stdout()))?;
    terminal.clear()?;

    run(&mut terminal, &mut state)?;

    // restore terminal
    disable_raw_mode()?;
    terminal.backend_mut().execute(LeaveAlternateScreen)?;
    terminal.backend_mut().execute(DisableMouseCapture)?;
    terminal.backend_mut().execute(ResetColor)?;
    terminal.backend_mut().execute(RestorePosition)?;
    terminal.show_cursor()?;
    Ok(())
}

fn run<B: Backend>(terminal: &mut Terminal<B>, state: &mut AppState) -> io::Result<()> {
    loop {
        terminal.draw(|frame| state.draw(frame)).unwrap();

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

            if !state.handle_key(&key) {
                return Ok(());
            }
        }
    }
}

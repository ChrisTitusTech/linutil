mod cli;
mod confirmation;
mod filter;
mod float;
mod floating_text;
mod hint;
mod root;
mod running_command;
mod state;
mod theme;

#[cfg(feature = "tips")]
mod tips;

use crate::cli::Args;
use clap::Parser;
use ratatui::{
    Terminal,
    backend::CrosstermBackend,
    crossterm::{
        ExecutableCommand,
        event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyEventKind},
        style::ResetColor,
        terminal::{EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode},
    },
};
use state::AppState;
use std::{
    io::{Result, Stdout, stdout},
    time::Duration,
};

fn main() -> Result<()> {
    let args = Args::parse();
    let mut state = AppState::new(args.clone());

    stdout().execute(EnterAlternateScreen)?;
    if args.mouse {
        stdout().execute(EnableMouseCapture)?;
    }

    enable_raw_mode()?;
    let mut terminal = Terminal::new(CrosstermBackend::new(stdout()))?;
    terminal.clear()?;

    run(&mut terminal, &mut state)?;

    // restore terminal
    disable_raw_mode()?;
    terminal.backend_mut().execute(LeaveAlternateScreen)?;
    if args.mouse {
        terminal.backend_mut().execute(DisableMouseCapture)?;
    }
    terminal.backend_mut().execute(ResetColor)?;
    terminal.show_cursor()?;

    Ok(())
}

fn run(terminal: &mut Terminal<CrosstermBackend<Stdout>>, state: &mut AppState) -> Result<()> {
    loop {
        terminal.draw(|frame| state.draw(frame)).unwrap();
        // Wait for an event
        if !event::poll(Duration::from_millis(10))? {
            continue;
        }

        // It's guaranteed that the `read()` won't block when the `poll()`
        // function returns `true`
        match event::read()? {
            Event::Key(key) => {
                if key.kind != KeyEventKind::Press && key.kind != KeyEventKind::Repeat {
                    continue;
                }

                if !state.handle_key(&key) {
                    return Ok(());
                }
            }
            Event::Mouse(mouse_event) => {
                if !state.handle_mouse(&mouse_event) {
                    return Ok(());
                }
            }
            _ => {}
        }
    }
}

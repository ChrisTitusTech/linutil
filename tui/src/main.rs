mod cli;
mod confirmation;
mod dashboard;
mod filter;
mod float;
mod floating_text;
mod hint;
mod intro;
mod logo;
mod root;
mod running_command;
mod script_preview;
mod stars;
mod state;
mod system_info;
mod theme;

#[cfg(feature = "tips")]
mod tips;

use crate::cli::Args;
use clap::Parser;
use ratatui::{
    backend::CrosstermBackend,
    crossterm::{
        event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyEventKind},
        style::ResetColor,
        terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
        ExecutableCommand,
    },
    Terminal,
};
use running_command::TERMINAL_UPDATED;
use state::AppState;
use std::{
    io::{stdout, Result, Stdout},
    sync::atomic::Ordering,
    time::{Duration, Instant},
};

fn main() -> Result<()> {
    let args = Args::parse();

    stdout().execute(EnterAlternateScreen)?;
    if args.mouse {
        stdout().execute(EnableMouseCapture)?;
    }

    let mut state = AppState::new(args.clone());

    enable_raw_mode()?;
    let mut terminal = Terminal::new(CrosstermBackend::new(stdout()))?;
    terminal.clear()?;

    let result = run(&mut terminal, &mut state, args.intro);

    // restore terminal
    disable_raw_mode()?;
    terminal.backend_mut().execute(LeaveAlternateScreen)?;
    if args.mouse {
        terminal.backend_mut().execute(DisableMouseCapture)?;
    }
    terminal.backend_mut().execute(ResetColor)?;
    terminal.show_cursor()?;

    result
}

fn run(
    terminal: &mut Terminal<CrosstermBackend<Stdout>>,
    state: &mut AppState,
    show_intro: bool,
) -> Result<()> {
    let mut intro = show_intro.then(Instant::now);
    loop {
        if let Some(started) = intro {
            let elapsed = started.elapsed();
            terminal.draw(|frame| {
                state.draw(frame);
                intro::apply(frame.buffer_mut(), elapsed);
            })?;
            if elapsed >= intro::DURATION {
                intro = None;
            }
        }
        // Wait for an event
        if !event::poll(Duration::from_millis(if intro.is_some() { 33 } else { 10 }))? {
            if intro.is_some() {
                continue;
            }
            let terminal_updated = TERMINAL_UPDATED
                .compare_exchange(true, false, Ordering::AcqRel, Ordering::Acquire)
                .is_ok();
            if terminal_updated || state.needs_animation_frame() {
                terminal.draw(|frame| state.draw(frame))?;
            }
            continue;
        }

        // It's guaranteed that the `read()` won't block when the `poll()`
        // function returns `true`
        match event::read()? {
            Event::Key(key) => {
                if key.kind != KeyEventKind::Press && key.kind != KeyEventKind::Repeat {
                    continue;
                }

                if intro.take().is_some() {
                    terminal.draw(|frame| state.draw(frame))?;
                    continue;
                }

                if !state.handle_key(&key) {
                    return Ok(());
                }
            }
            Event::Mouse(_) if intro.is_some() => continue,
            Event::Mouse(mouse_event) if !state.handle_mouse(&mouse_event) => {
                return Ok(());
            }
            _ => {}
        }
        if intro.is_none() {
            terminal.draw(|frame| state.draw(frame))?;
        }
    }
}

mod confirmation;
mod filter;
mod float;
mod floating_text;
mod hint;
mod running_command;
pub mod state;
mod theme;

use std::{
    io::{self, stdout},
    time::Duration,
};

use crate::theme::Theme;
use clap::Parser;
use crossterm::{
    event::{self, DisableMouseCapture, Event, KeyCode, KeyEvent, KeyEventKind},
    style::ResetColor,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    ExecutableCommand,
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Layout},
    style::Stylize,
    widgets::{Paragraph, Wrap},
    Terminal,
};
use state::AppState;

// Linux utility toolbox
#[derive(Debug, Parser)]
struct Args {
    #[arg(short, long, value_enum)]
    #[arg(default_value_t = Theme::Default)]
    #[arg(help = "Set the theme to use in the application")]
    theme: Theme,
    #[arg(long, default_value_t = false)]
    #[clap(help = "Show all available options, disregarding compatibility checks (UNSAFE)")]
    override_validation: bool,
}

fn main() -> io::Result<()> {
    if sudo::check() != sudo::RunningAs::User && !Args::parse().allow_root {
        eprintln!("Error: This program is not intended to be run with elevated privileges.");
        eprintln!("To bypass this restriction, use the '--allow-root' flag.");
        std::process::exit(1);
    }

    let args = Args::parse();

    let mut state = AppState::new(args.theme, args.override_validation);

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
    terminal.show_cursor()?;

    Ok(())
}

fn run(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    state: &mut AppState,
) -> io::Result<()> {
    if sudo::check() == sudo::RunningAs::Root {
        terminal.draw(|frame| {
            let root_warn = Paragraph::new(
                r#"
!!!!!!!!!!!!!! YOU ARE ABOUT TO RUN LINUTIL AS ROOT !!!!!!!!!!!!!!

This utility prioritizes compatibility with non-root environments.
Some scripts may work without any issues, some may not.
You have been warned!

!!!!!!!!!!!!!!!!!!!!!! PROCEED WITH CAUTION !!!!!!!!!!!!!!!!!!!!!!

Press [y] to continue, [n] to abort
"#,
            )
            .on_black()
            .white()
            .alignment(Alignment::Center)
            .wrap(Wrap { trim: true });

            let rects = Layout::vertical([
                Constraint::Fill(1),
                Constraint::Length(10),
                Constraint::Fill(1),
            ])
            .split(frame.area());

            let centered = rects[1];

            frame.render_widget(root_warn, centered);
        })?;

        loop {
            match event::read()? {
                Event::Key(
                    KeyEvent {
                        code: KeyCode::Char('y'),
                        ..
                    }
                    | KeyEvent {
                        code: KeyCode::Char('Y'),
                        ..
                    },
                ) => {
                    break;
                }
                Event::Key(
                    KeyEvent {
                        code: KeyCode::Char('n'),
                        ..
                    }
                    | KeyEvent {
                        code: KeyCode::Char('N'),
                        ..
                    },
                ) => {
                    return Ok(());
                }
                _ => {}
            }
        }
    }

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

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
    path::PathBuf,
    time::Duration,
};

use crate::theme::Theme;
use clap::Parser;

use ratatui::{
    backend::CrosstermBackend,
    crossterm::{
        event::{self, DisableMouseCapture, Event, KeyEventKind},
        style::ResetColor,
        terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
        ExecutableCommand,
    },
    Terminal,
};
use state::AppState;

// Linux utility toolbox
#[derive(Debug, Parser)]
struct Args {
    #[arg(short, long, help = "Path to the configuration file")]
    config: Option<PathBuf>,
    #[arg(short, long, value_enum)]
    #[arg(default_value_t = Theme::Default)]
    #[arg(help = "Set the theme to use in the application")]
    theme: Theme,
    #[arg(
        short = 'y',
        long,
        help = "Skip confirmation prompt before executing commands"
    )]
    skip_confirmation: bool,
    #[arg(long, default_value_t = false)]
    #[clap(help = "Show all available options, disregarding compatibility checks (UNSAFE)")]
    override_validation: bool,
    #[arg(long, default_value_t = false)]
    #[clap(help = "Bypass the terminal size limit")]
    size_bypass: bool,
}

fn main() -> io::Result<()> {
    let args = Args::parse();

    let mut state = AppState::new(
        args.config,
        args.theme,
        args.override_validation,
        args.size_bypass,
        args.skip_confirmation,
    );

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

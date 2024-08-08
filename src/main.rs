mod float;
mod floating_text;
mod list;
mod running_command;
mod search;
pub mod state;
mod theme;

use crate::search::SearchBar;
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
use float::Float;
use include_dir::include_dir;
use list::CustomList;
use ratatui::{
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Direction, Layout},
    Terminal,
};
use running_command::RunningCommand;
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

    let state = AppState {
        theme,
        temp_path: temp_dir.path().to_owned(),
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
    //Create the command list
    let mut custom_list = CustomList::new();
    //Create the float to hold command output
    let mut command_float = Float::new(60, 60);
    //Create the search bar
    let mut search_bar = SearchBar::new();

    loop {
        // Always redraw
        terminal
            .draw(|frame| {
                //Split the terminal into 2 vertical chunks
                //One for the search bar and one for the command list
                let chunks = Layout::default()
                    .direction(Direction::Vertical)
                    .constraints([Constraint::Length(3), Constraint::Min(1)].as_ref())
                    .split(frame.size());

                //Render the search bar
                search_bar.draw(frame, chunks[0], state);
                //Render the command list (Second chunk of the screen)
                custom_list.draw(frame, chunks[1], state);
                //Render the command float in the custom_list chunk
                command_float.draw(frame, chunks[1]);
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

            //Send the key to the float
            //If we receive true, then the float processed the input
            //If that's the case, don't propagate input to other widgets
            if !command_float.handle_key_event(&key) {
                //Insert user input into the search bar
                //Send the keys to the search bar
                if search_bar.is_search_active() {
                    let search_query = search_bar.handle_key(key);
                    custom_list.reset_selection();
                    custom_list.filter(search_query);
                }
                // Else, send them to the list
                else if let Some(cmd) = custom_list.handle_key(key, state) {
                    command_float.set_content(Some(RunningCommand::new(cmd, state)));
                } else {
                    // Handle keys while not in search mode
                    match key.code {
                        // Exit the program
                        KeyCode::Char('q') => return Ok(()),
                        //Activate search mode if the forward slash key gets pressed
                        KeyCode::Char('/') => {
                            search_bar.activate_search();
                            continue;
                        }
                        _ => {}
                    }
                }
            }
        }
    }
}

mod float;
mod floating_text;
mod list;
mod running_command;
pub mod state;
mod systeminfo;
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
use float::Float;
use include_dir::include_dir;
use list::CustomList;
use ratatui::{
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Direction, Layout},
    style::{Color, Style},
    text::Span,
    widgets::{Block, Borders, Paragraph},
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
    //Create the search field
    let mut search_input = String::new();
    //Create the command list
    let mut custom_list = CustomList::new();
    //Create the float to hold command output
    let mut command_float = Float::new(60, 60);
    let mut in_search_mode = false;

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

                //Set the search bar text (If empty use the placeholder)
                let display_text = if search_input.is_empty() {
                    if in_search_mode {
                        Span::raw("")
                    } else {
                        Span::raw("Press / to search")
                    }
                } else {
                    Span::raw(&search_input)
                };

                //Create the search bar widget
                let mut search_bar = Paragraph::new(display_text)
                    .block(Block::default().borders(Borders::ALL).title("Search"))
                    .style(Style::default().fg(Color::DarkGray));

                //Change the color if in search mode
                if in_search_mode {
                    search_bar = search_bar.clone().style(Style::default().fg(Color::Blue));
                }

                //Render the search bar (First chunk of the screen)
                frame.render_widget(search_bar, chunks[0]);
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
                if in_search_mode {
                    match key.code {
                        KeyCode::Char(c) => {
                            search_input.push(c);
                            custom_list.filter(search_input.clone());
                        }
                        KeyCode::Backspace => {
                            search_input.pop();
                            custom_list.filter(search_input.clone());
                        }
                        KeyCode::Esc => {
                            search_input = String::new();
                            custom_list.filter(search_input.clone());
                            in_search_mode = false
                        }
                        KeyCode::Enter => {
                            in_search_mode = false;
                            custom_list.reset_selection();
                        }
                        _ => {}
                    }
                } else if let Some(cmd) = custom_list.handle_key(key, state) {
                    command_float.set_content(Some(RunningCommand::new(cmd, state)));
                } else {
                    // Handle keys while not in search mode
                    match key.code {
                        // Exit the program
                        KeyCode::Char('q') => return Ok(()),
                        //Activate search mode if the forward slash key gets pressed
                        KeyCode::Char('/') => {
                            in_search_mode = true;
                            continue;
                        }
                        _ => {}
                    }
                }
            }
        }
    }
}

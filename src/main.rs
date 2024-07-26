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
    event::{self, DisableMouseCapture, Event, KeyCode, KeyEventKind},
    style::ResetColor,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    ExecutableCommand,
};
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
    let mut search_input = String::new();
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
                custom_list.draw(frame, chunks[1], search_input.clone());

                if let Some(ref mut command) = &mut command_opt {
                    command.draw(frame);
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
                //Activate search mode if the forward slash key gets pressed
                if key.code == KeyCode::Char('/') {
                    // Enter search mode
                    in_search_mode = true;
                    continue;
                }
                //Insert user input into the search bar
                if in_search_mode {
                    match key.code {
                        KeyCode::Char(c) => search_input.push(c),
                        KeyCode::Backspace => {
                            search_input.pop();
                        }
                        KeyCode::Esc => {
                            search_input = String::new();
                            in_search_mode = false
                        }
                        KeyCode::Enter => in_search_mode = false,
                        _ => {}
                    }
                } else if let Some(cmd) = custom_list.handle_key(key) {
                    command_opt = Some(RunningCommand::new(cmd));
                }
            }
        }
    }
}

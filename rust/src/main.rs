use crossterm::{
    event::{self, KeyCode, KeyEventKind},
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    ExecutableCommand,
};
use ratatui::{prelude::*, widgets::*};
use std::io::{stdout, Result};

/// Entry point of the application.
fn main() -> Result<()> {
    // Enter an alternate screen and enable raw mode for terminal interaction.
    stdout().execute(EnterAlternateScreen)?;
    enable_raw_mode()?;

    // Initialize the terminal with a Crossterm backend.
    let mut terminal = Terminal::new(CrosstermBackend::new(stdout()))?;
    terminal.clear()?;

    // Initialize the state for a list and define the list items.
    let mut state = ListState::default();
    let items = ["MyBash", "Neovim", "Quit"];
    state.select(Some(0)); // Start with the first item selected.

    // Main event loop.
    loop {
        // Draw UI components on each iteration.
        terminal.draw(|frame| {
            let area = frame.size();
            let list = List::new(items)
                .block(Block::default().title("List").borders(Borders::ALL))
                .highlight_style(Style::new().bg(Color::Blue))
                .highlight_symbol(">>")
                .repeat_highlight_symbol(true);

            // Render the list and a paragraph widget.
            frame.render_stateful_widget(list, area, &mut state);
            frame.render_widget(
                Paragraph::new("The Linux Toolbox (press 'q' to quit)")
                    .white()
                    .on_black(),
                area,
            );
        })?;

        // Handle keyboard input.
        if event::poll(std::time::Duration::from_millis(16))? {
            if let event::Event::Key(key) = event::read()? {
                match key.kind {
                    KeyEventKind::Press | KeyEventKind::Repeat => match key.code {
                        KeyCode::Char('j') => {
                            // Move selection down in the list.
                            let selected = state.selected().unwrap_or(0);
                            state.select(Some((selected + 1).min(items.len() - 1)));
                        }
                        KeyCode::Char('k') => {
                            // Move selection up in the list.
                            let selected = state.selected().unwrap_or(0);
                            state.select(Some(selected.saturating_sub(1)));
                        }
                        KeyCode::Char('q') => {
                            // Exit the loop and close the application.
                            break;
                        }
                        _ => (),
                    },
                    _ => (),
                }
            }
        }
    }

    // Exit the alternate screen and disable raw mode before exiting.
    stdout().execute(LeaveAlternateScreen)?;
    disable_raw_mode()?;
    Ok(())
}

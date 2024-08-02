use crossterm::event::{KeyCode, KeyEvent};
use ratatui::{
    layout::Rect,
    style::Style,
    text::Span,
    widgets::{Block, Borders, Paragraph},
    Frame,
};

use crate::state::AppState;

pub struct SearchBar {
    search_input: String,
    in_search_mode: bool,
}

impl SearchBar {
    pub fn new() -> Self {
        SearchBar {
            search_input: String::new(),
            in_search_mode: false,
        }
    }

    pub fn activate_search(&mut self) {
        self.in_search_mode = true;
    }

    pub fn deactivate_search(&mut self) {
        self.in_search_mode = false;
    }

    pub fn is_search_active(&self) -> bool {
        self.in_search_mode
    }

    pub fn draw(&self, frame: &mut Frame, area: Rect, state: &AppState) {
        //Set the search bar text (If empty use the placeholder)
        let display_text = if !self.in_search_mode && self.search_input.is_empty() {
            Span::raw("Press / to search")
        } else {
            Span::raw(&self.search_input)
        };

        //Create the search bar widget
        let mut search_bar = Paragraph::new(display_text)
            .block(Block::default().borders(Borders::ALL).title("Search"))
            .style(Style::default().fg(state.theme.unfocused_color));

        //Change the color if in search mode
        if self.in_search_mode {
            search_bar = search_bar
                .clone()
                .style(Style::default().fg(state.theme.focused_color));
        }

        //Render the search bar (First chunk of the screen)
        frame.render_widget(search_bar, area);
    }

    pub fn handle_key(&mut self, event: KeyEvent) -> String {
        //Insert user input into the search bar
        match event.code {
            KeyCode::Char(c) => {
                self.search_input.push(c);
            }
            KeyCode::Backspace => {
                self.search_input.pop();
            }
            KeyCode::Esc => {
                self.search_input = String::new();
                self.in_search_mode = false;
            }
            KeyCode::Enter => {
                self.in_search_mode = false;
            }
            _ => {}
        }
        self.search_input.clone()
    }
}

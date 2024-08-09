use crate::float::FloatContent;
use crossterm::event::{KeyCode, KeyEvent};
use ratatui::{
    layout::Rect,
    style::{Style, Stylize},
    text::Line,
    widgets::{Block, Borders, List},
    Frame,
};

pub struct FloatingText {
    text: Vec<String>,
    scroll: usize,
}

impl FloatingText {
    pub fn new(text: Vec<String>) -> Self {
        Self { text, scroll: 0 }
    }

    fn scroll_down(&mut self) {
        if self.scroll + 1 < self.text.len() {
            self.scroll += 1;
        }
    }

    fn scroll_up(&mut self) {
        if self.scroll > 0 {
            self.scroll -= 1;
        }
    }
}

impl FloatContent for FloatingText {
    fn draw(&mut self, frame: &mut Frame, area: Rect) {
        // Define the Block with a border and background color
        let block = Block::default()
            .borders(Borders::ALL)
            .style(Style::default());

        // Draw the Block first
        frame.render_widget(block.clone(), area);

        // Calculate the inner area to ensure text is not drawn over the border
        let inner_area = block.inner(area);

        // Create the list of lines to be displayed
        let lines: Vec<Line> = self
            .text
            .iter()
            .skip(self.scroll)
            .take(inner_area.height as usize)
            .map(|line| Line::from(line.as_str()))
            .collect();

        // Create list widget
        let list = List::new(lines)
            .block(Block::default())
            .highlight_style(Style::default().reversed());

        // Render the list inside the bordered area
        frame.render_widget(list, inner_area);
    }

    fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        match key.code {
            KeyCode::Down | KeyCode::Char('j') => {
                self.scroll_down();
                true
            }
            KeyCode::Up | KeyCode::Char('k') => {
                self.scroll_up();
                true
            }
            _ => false,
        }
    }

    fn is_finished(&self) -> bool {
        true
    }
}

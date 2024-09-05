use crate::theme::Theme;

use ratatui::{
    layout::Rect,
    style::Style,
    widgets::{Block, Borders, Paragraph},
    Frame,
};


pub struct Tips {
    text_to_display: String
}

impl Tips {
    pub fn new() -> Self {
        Self {
            text_to_display: "Press Q to Exit".to_string()
        }
    }

    pub fn draw_tips(&self, frame: &mut Frame, area: Rect, theme: &Theme){

        let search_bar = Paragraph::new(self.text_to_display.to_string())
            .block(Block::default().borders(Borders::ALL).title("Linux Toolbox".to_string()))
            .style(Style::default().fg(theme.unfocused_color()));
        frame.render_widget(search_bar, area);
    }
}
use crossterm::event::{KeyCode, KeyEvent};
use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    Frame,
};

pub trait FloatContent {
    fn draw(&mut self, frame: &mut Frame, area: Rect);
    fn handle_key_event(&mut self, key: &KeyEvent) -> bool;
    fn is_finished(&self) -> bool;
}

pub struct Float {
    content: Box<dyn FloatContent>,
    width_percent: u16,
    height_percent: u16,
}

impl Float {
    pub fn new(content: Box<dyn FloatContent>, width_percent: u16, height_percent: u16) -> Self {
        Self {
            content,
            width_percent,
            height_percent,
        }
    }

    fn floating_window(&self, size: Rect) -> Rect {
        let hor_float = Layout::default()
            .constraints([
                Constraint::Percentage((100 - self.width_percent) / 2),
                Constraint::Percentage(self.width_percent),
                Constraint::Percentage((100 - self.width_percent) / 2),
            ])
            .direction(Direction::Horizontal)
            .split(size)[1];

        Layout::default()
            .constraints([
                Constraint::Percentage((100 - self.height_percent) / 2),
                Constraint::Percentage(self.height_percent),
                Constraint::Percentage((100 - self.height_percent) / 2),
            ])
            .direction(Direction::Vertical)
            .split(hor_float)[1]
    }

    pub fn draw(&mut self, frame: &mut Frame, parent_area: Rect) {
        let popup_area = self.floating_window(parent_area);

        let content_area = Rect {
            x: popup_area.x,
            y: popup_area.y,
            width: popup_area.width,
            height: popup_area.height,
        };

        self.content.draw(frame, content_area);
    }

    // Returns true if the floating window is finished.
    pub fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        match key.code {
            KeyCode::Enter | KeyCode::Char('p') | KeyCode::Esc | KeyCode::Char('q')
                if self.content.is_finished() =>
            {
                true
            }
            _ => self.content.handle_key_event(key),
        }
    }
}

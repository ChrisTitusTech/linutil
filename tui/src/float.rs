use ratatui::{
    crossterm::event::{KeyCode, KeyEvent},
    layout::{Constraint, Direction, Layout, Rect},
    Frame,
};

use crate::hint::Shortcut;

pub trait FloatContent {
    fn draw(&mut self, frame: &mut Frame, area: Rect);
    fn handle_key_event(&mut self, key: &KeyEvent) -> bool;
    fn is_finished(&self) -> bool;
    fn get_shortcut_list(&self) -> (&str, Box<[Shortcut]>);
}

pub struct Float<Content: FloatContent + ?Sized> {
    pub content: Box<Content>,
    width_percent: u16,
    height_percent: u16,
}

impl<Content: FloatContent + ?Sized> Float<Content> {
    pub fn new(content: Box<Content>, width_percent: u16, height_percent: u16) -> Self {
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
        self.content.draw(frame, popup_area);
    }

    // Returns true if the floating window is finished.
    pub fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        match key.code {
            KeyCode::Enter
            | KeyCode::Char('p')
            | KeyCode::Char('d')
            | KeyCode::Char('g')
            | KeyCode::Char('q')
            | KeyCode::Esc
                if self.content.is_finished() =>
            {
                true
            }
            _ => self.content.handle_key_event(key),
        }
    }

    pub fn get_shortcut_list(&self) -> (&str, Box<[Shortcut]>) {
        self.content.get_shortcut_list()
    }
}

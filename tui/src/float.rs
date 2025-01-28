use crate::{hint::Shortcut, theme::Theme};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, MouseEvent},
    layout::{Constraint, Layout, Rect},
    Frame,
};

pub trait FloatContent {
    fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &Theme);
    fn handle_key_event(&mut self, key: &KeyEvent) -> bool;
    fn handle_mouse_event(&mut self, key: &MouseEvent) -> bool;
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
        let hor_float = Layout::horizontal([
            Constraint::Percentage((100 - self.width_percent) / 2),
            Constraint::Percentage(self.width_percent),
            Constraint::Percentage((100 - self.width_percent) / 2),
        ])
        .split(size)[1];

        Layout::vertical([
            Constraint::Percentage((100 - self.height_percent) / 2),
            Constraint::Percentage(self.height_percent),
            Constraint::Percentage((100 - self.height_percent) / 2),
        ])
        .split(hor_float)[1]
    }

    pub fn draw(&mut self, frame: &mut Frame, parent_area: Rect, theme: &Theme) {
        let popup_area = self.floating_window(parent_area);
        self.content.draw(frame, popup_area, theme);
    }

    pub fn handle_mouse_event(&mut self, event: &MouseEvent) {
        self.content.handle_mouse_event(event);
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

use crossterm::event::{KeyCode, KeyEvent};
use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    Frame,
};

pub trait FloatContent {
    fn draw(&mut self, frame: &mut Frame, area: Rect);
    fn handle_key_event(&mut self, key: &KeyEvent) -> bool;
    // Lets the float know if it's content has finished.
    // This is used to know if we can close the float.
    // The running_command only returns true after the command has finished.
    // The preview command always returns true.
    fn is_finished(&self) -> bool;
}

pub struct Float<T: FloatContent> {
    content: Option<T>,
    width_percent: u16,
    height_percent: u16,
}

impl<T: FloatContent> Float<T> {
    pub fn new(width_percent: u16, height_percent: u16) -> Self {
        Self {
            content: None,
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

        if let Some(content) = &mut self.content {
            let content_area = Rect {
                x: popup_area.x,
                y: popup_area.y,
                width: popup_area.width,
                height: popup_area.height,
            };

            content.draw(frame, content_area);
        }
    }

    // Returns true if the key was processed by this Float.
    pub fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        if let Some(content) = &mut self.content {
            match key.code {
                KeyCode::Enter | KeyCode::Char('p') | KeyCode::Esc | KeyCode::Char('q') => {
                    if content.is_finished() {
                        self.content = None;
                    } else {
                        content.handle_key_event(key);
                    }
                }
                _ => {
                    content.handle_key_event(key);
                }
            }
            true
        } else {
            false
        }
    }

    pub fn get_content(&self) -> &Option<T> {
        &self.content
    }

    pub fn set_content(&mut self, content: Option<T>) {
        self.content = content;
    }
}

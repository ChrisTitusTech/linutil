use std::borrow::Cow;

use crate::{float::FloatContent, hint::Shortcut};

use ratatui::{
    crossterm::event::{KeyCode, KeyEvent},
    layout::Alignment,
    prelude::*,
    widgets::{Block, Borders, Clear, List},
};

pub enum ConfirmStatus {
    Confirm,
    Abort,
    None,
}

pub struct ConfirmPrompt {
    pub names: Box<[String]>,
    pub status: ConfirmStatus,
    scroll: usize,
}

impl ConfirmPrompt {
    pub fn new(names: &[&str]) -> Self {
        let max_count_str = format!("{}", names.len());
        let names = names
            .iter()
            .zip(1..)
            .map(|(name, n)| {
                let count_str = format!("{n}");
                let space_str = (0..(max_count_str.len() - count_str.len()))
                    .map(|_| ' ')
                    .collect::<String>();
                format!("{space_str}{n}. {name}")
            })
            .collect();

        Self {
            names,
            status: ConfirmStatus::None,
            scroll: 0,
        }
    }

    pub fn scroll_down(&mut self) {
        if self.scroll < self.names.len() - 1 {
            self.scroll += 1;
        }
    }

    pub fn scroll_up(&mut self) {
        if self.scroll > 0 {
            self.scroll -= 1;
        }
    }
}

impl FloatContent for ConfirmPrompt {
    fn draw(&mut self, frame: &mut Frame, area: Rect) {
        let block = Block::default()
            .borders(Borders::ALL)
            .border_set(ratatui::symbols::border::ROUNDED)
            .title(" Confirm selections ")
            .title_bottom(" [y] to continue, [n] to abort ")
            .title_alignment(Alignment::Center)
            .title_style(Style::default().bold())
            .style(Style::default());

        frame.render_widget(block.clone(), area);

        let inner_area = block.inner(area);

        let paths_text = self
            .names
            .iter()
            .skip(self.scroll)
            .map(|p| {
                let span = Span::from(Cow::<'_, str>::Borrowed(p));
                Line::from(span).style(Style::default())
            })
            .collect::<Text>();

        frame.render_widget(Clear, inner_area);
        frame.render_widget(List::new(paths_text), inner_area);
    }

    fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        use KeyCode::*;
        self.status = match key.code {
            Char('y') | Char('Y') => ConfirmStatus::Confirm,
            Char('n') | Char('N') | Esc | Char('q') => ConfirmStatus::Abort,
            Char('j') => {
                self.scroll_down();
                ConfirmStatus::None
            }
            Char('k') => {
                self.scroll_up();
                ConfirmStatus::None
            }
            _ => ConfirmStatus::None,
        };

        false
    }

    fn is_finished(&self) -> bool {
        use ConfirmStatus::*;
        match self.status {
            Confirm | Abort => true,
            None => false,
        }
    }

    fn get_shortcut_list(&self) -> (&str, Box<[Shortcut]>) {
        (
            "Confirmation prompt",
            Box::new([
                Shortcut::new("Continue", ["Y", "y"]),
                Shortcut::new("Abort", ["N", "n", "q", "Esc"]),
                Shortcut::new("Scroll up", ["k"]),
                Shortcut::new("Scroll down", ["j"]),
                Shortcut::new("Close linutil", ["CTRL-c"]),
            ]),
        )
    }
}

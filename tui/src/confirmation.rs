use crate::{float::FloatContent, hint::Shortcut, shortcuts, theme};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, MouseEvent, MouseEventKind},
    layout::Alignment,
    prelude::*,
    symbols::border,
    widgets::{Block, Clear, List},
};
use std::borrow::Cow;

pub enum ConfirmStatus {
    Confirm,
    Abort,
    None,
}

pub struct ConfirmPrompt {
    inner_area_height: usize,
    names: Box<[String]>,
    scroll: usize,
    pub status: ConfirmStatus,
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
            inner_area_height: 0,
            names,
            scroll: 0,
            status: ConfirmStatus::None,
        }
    }

    pub fn scroll_down(&mut self) {
        if self.scroll + self.inner_area_height < self.names.len() - 1 {
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
    fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &theme::Theme) {
        let block = Block::bordered()
            .border_set(border::PLAIN)
            .border_style(Style::default().fg(theme.focused_color()))
            .title(" CONFIRM SELECTIONS ")
            .title_bottom(Line::from(vec![
                Span::raw(" ["),
                Span::styled("y", Style::default().fg(theme.success_color())),
                Span::raw("] to continue ["),
                Span::styled("n", Style::default().fg(theme.fail_color())),
                Span::raw("] to abort "),
            ]))
            .title_alignment(Alignment::Center)
            .title_style(Style::default().fg(theme.tab_color()).bold())
            .style(Style::default());

        let inner_area = block.inner(area);
        self.inner_area_height = inner_area.height as usize;

        frame.render_widget(Clear, area);
        frame.render_widget(block, area);

        let paths_text = self
            .names
            .iter()
            .skip(self.scroll)
            .map(|p| {
                let span = Span::from(Cow::<'_, str>::Borrowed(p));
                Line::from(span).style(Style::default())
            })
            .collect::<Text>();

        frame.render_widget(List::new(paths_text), inner_area);
    }

    fn handle_mouse_event(&mut self, event: &MouseEvent) -> bool {
        match event.kind {
            MouseEventKind::ScrollDown => {
                self.scroll_down();
            }
            MouseEventKind::ScrollUp => {
                self.scroll_up();
            }
            _ => {}
        }
        false
    }

    fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        use ConfirmStatus::*;
        use KeyCode::{Char, Down, Esc, Up};
        self.status = match key.code {
            Char('y') | Char('Y') => Confirm,
            Char('n') | Char('N') | Esc | Char('q') => Abort,
            Char('j') | Char('J') | Down => {
                self.scroll_down();
                None
            }
            Char('k') | Char('K') | Up => {
                self.scroll_up();
                None
            }
            _ => None,
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
            shortcuts!(
                ("Continue", ["Y", "y"]),
                ("Abort", ["N", "n", "q", "Esc"]),
                ("Scroll up", ["k", "Up"]),
                ("Scroll down", ["j", "Down"]),
                ("Close linutil", ["CTRL-c"]),
            ),
        )
    }
}

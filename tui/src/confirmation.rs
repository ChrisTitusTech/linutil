use crate::{float::FloatContent, theme};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, MouseEvent, MouseEventKind},
    prelude::*,
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
        if self.scroll + self.inner_area_height < self.names.len().saturating_sub(1) {
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
            .border_set(crate::dashboard::border_set())
            .border_style(Style::default().fg(theme.focused_color()))
            .title_top(
                Line::styled(
                    " Confirmation ",
                    Style::default().fg(theme.tab_color()).bold(),
                )
                .centered(),
            )
            .title_bottom(
                Line::from(vec![
                    Span::styled(" [", Style::default().fg(theme.unfocused_color())),
                    Span::styled("y", Style::default().fg(theme.success_color())),
                    Span::styled(
                        "] to continue [",
                        Style::default().fg(theme.unfocused_color()),
                    ),
                    Span::styled("n", Style::default().fg(theme.fail_color())),
                    Span::styled("] to cancel ", Style::default().fg(theme.unfocused_color())),
                ])
                .centered(),
            )
            .style(Style::default().bg(theme.bg()).fg(theme.cmd_color()));

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
            Char('y') => Confirm,
            Char('n' | 'q') | Esc => Abort,
            Char('j') | Down => {
                self.scroll_down();
                None
            }
            Char('k') | Up => {
                self.scroll_up();
                None
            }
            _ => None,
        };
        self.is_finished()
    }

    fn is_finished(&self) -> bool {
        use ConfirmStatus::*;
        match self.status {
            Confirm | Abort => true,
            None => false,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::{backend::TestBackend, Terminal};

    #[test]
    fn prompt_uses_the_theme_background() {
        let theme = theme::Theme::Default;
        let mut prompt = ConfirmPrompt::new(&["Google Chrome"]);
        let mut terminal = Terminal::new(TestBackend::new(40, 10)).unwrap();
        terminal
            .draw(|frame| prompt.draw(frame, frame.area(), &theme))
            .unwrap();
        let buffer = terminal.backend().buffer();
        assert!(buffer.content.iter().all(|cell| cell.bg == theme.bg()));
    }
}

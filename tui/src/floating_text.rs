use crate::{float::FloatContent, theme::Theme};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, MouseEvent, MouseEventKind},
    prelude::*,
    widgets::{Block, Borders, Clear, Paragraph},
};
use unicode_width::UnicodeWidthStr;

pub struct FloatingText<'a> {
    inner_area_size: (usize, usize),
    mode_title: String,
    processed_text: Text<'a>,
    wrapped_text: Text<'static>,
    wrapped_width: Option<u16>,
    scroll: (u16, u16),
    wrap_words: bool,
    footer: Option<String>,
    close_key: Option<char>,
}

impl<'a> FloatingText<'a> {
    pub fn new(text: String, title: &str, wrap_words: bool) -> Self {
        Self::from_text(Text::from(text), title, wrap_words)
    }

    pub fn from_text(text: Text<'a>, title: &str, wrap_words: bool) -> Self {
        Self {
            inner_area_size: (0, 0),
            mode_title: title.to_string(),
            processed_text: text,
            wrapped_text: Text::default(),
            wrapped_width: None,
            scroll: (0, 0),
            wrap_words,
            footer: None,
            close_key: None,
        }
    }

    pub fn with_footer(mut self, footer: &str) -> Self {
        self.footer = Some(footer.to_owned());
        self
    }

    /// Closes on this key and Esc only, e.g. the key that opened the window.
    /// Without one, Enter and Esc close it.
    pub fn with_close_key(mut self, key: char) -> Self {
        self.close_key = Some(key);
        self
    }

    fn max_scroll(&self) -> (u16, u16) {
        let lines = if self.wrap_words {
            &self.wrapped_text.lines
        } else {
            &self.processed_text.lines
        };
        let vertical = lines.len().saturating_sub(self.inner_area_size.1.max(1));
        let horizontal = if self.wrap_words {
            0
        } else {
            lines
                .iter()
                .map(Line::width)
                .max()
                .unwrap_or(0)
                .saturating_sub(self.inner_area_size.0.max(1))
        };
        (
            vertical.min(u16::MAX as usize) as u16,
            horizontal.min(u16::MAX as usize) as u16,
        )
    }

    fn clamp_scroll(&mut self) {
        let maximum = self.max_scroll();
        self.scroll.0 = self.scroll.0.min(maximum.0);
        self.scroll.1 = self.scroll.1.min(maximum.1);
    }

    fn scroll_down(&mut self) {
        self.scroll.0 = self.scroll.0.saturating_add(1);
        self.clamp_scroll();
    }

    fn scroll_up(&mut self) {
        self.scroll.0 = self.scroll.0.saturating_sub(1);
    }

    fn scroll_left(&mut self) {
        self.scroll.1 = self.scroll.1.saturating_sub(1);
    }

    fn scroll_right(&mut self) {
        self.scroll.1 = self.scroll.1.saturating_add(1);
        self.clamp_scroll();
    }
}

// Cache the visual rows and render those same rows, so scroll limits always
// agree with wrapping, including wide graphemes and styled help columns.
pub(crate) fn wrapped_text(text: &Text<'_>, width: u16) -> Text<'static> {
    if width == 0 {
        return Text::default();
    }
    let mut lines = Vec::new();
    for line in &text.lines {
        let graphemes: Vec<_> = line
            .styled_graphemes(text.style)
            .filter(|grapheme| grapheme.symbol.width() <= width as usize)
            .collect();
        if graphemes.is_empty() {
            lines.push(Line::default());
            continue;
        }
        let mut start = 0;
        while start < graphemes.len() {
            let mut end = start;
            let mut used = 0;
            let mut word_break = None;
            while end < graphemes.len() {
                let grapheme = &graphemes[end];
                let cell_width = grapheme.symbol.width();
                if used + cell_width > width as usize {
                    break;
                }
                if end > start && grapheme.is_whitespace() && !graphemes[end - 1].is_whitespace() {
                    word_break = Some(end);
                }
                used += cell_width;
                end += 1;
            }
            let mut next = end;
            if end < graphemes.len() {
                if let Some(boundary) = word_break {
                    end = boundary;
                    next = boundary;
                    while next < graphemes.len() && graphemes[next].is_whitespace() {
                        next += 1;
                    }
                }
            }
            let mut spans: Vec<Span<'static>> = Vec::new();
            for grapheme in &graphemes[start..end] {
                if let Some(last) = spans.last_mut().filter(|last| last.style == grapheme.style) {
                    last.content.to_mut().push_str(grapheme.symbol);
                } else {
                    spans.push(Span::styled(grapheme.symbol.to_owned(), grapheme.style));
                }
            }
            let mut wrapped = Line::from(spans);
            wrapped.alignment = line.alignment;
            lines.push(wrapped);
            start = next;
        }
    }
    Text::from(lines)
}

impl FloatContent for FloatingText<'_> {
    fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &Theme) {
        let block = Block::default()
            .borders(Borders::ALL)
            .border_set(crate::dashboard::border_set())
            .border_style(Style::default().fg(theme.focused_color()))
            .title(self.mode_title.as_str())
            .title_alignment(Alignment::Center)
            .title_style(Style::default().fg(theme.tab_color()).bold())
            .title_bottom(
                Line::from(self.footer.as_deref().unwrap_or_default())
                    .style(theme.unfocused_color())
                    .centered(),
            )
            .style(Style::default().bg(theme.bg()).fg(theme.cmd_color()));
        let inner = block.inner(area);
        let content = inner.inner(Margin::new(
            u16::from(inner.width >= 3),
            u16::from(inner.height >= 5),
        ));
        frame.render_widget(Clear, area);
        frame.render_widget(block, area);
        self.inner_area_size = (content.width as usize, content.height as usize);
        if self.wrap_words && self.wrapped_width != Some(content.width) {
            self.wrapped_text = wrapped_text(&self.processed_text, content.width);
            self.wrapped_width = Some(content.width);
        }
        self.clamp_scroll();
        let text = if self.wrap_words {
            self.wrapped_text.clone()
        } else {
            self.processed_text.clone()
        };
        frame.render_widget(Paragraph::new(text).scroll(self.scroll), content);
    }

    fn handle_mouse_event(&mut self, event: &MouseEvent) -> bool {
        match event.kind {
            MouseEventKind::ScrollDown => self.scroll_down(),
            MouseEventKind::ScrollUp => self.scroll_up(),
            MouseEventKind::ScrollLeft => self.scroll_left(),
            MouseEventKind::ScrollRight => self.scroll_right(),
            _ => {}
        }
        false
    }

    fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        use KeyCode::{Char, Down, End, Enter, Esc, Home, Left, PageDown, PageUp, Right, Up};
        match key.code {
            Esc => return true,
            Enter if self.close_key.is_none() => return true,
            Char(c) if self.close_key == Some(c) => return true,
            Down | Char('j') => self.scroll_down(),
            Up | Char('k') => self.scroll_up(),
            Left | Char('h') => self.scroll_left(),
            Right | Char('l') => self.scroll_right(),
            PageDown => self.scroll.0 = self.scroll.0.saturating_add(10),
            PageUp => self.scroll.0 = self.scroll.0.saturating_sub(10),
            Home => self.scroll = (0, 0),
            End => self.scroll.0 = u16::MAX,
            _ => {}
        }
        self.clamp_scroll();
        false
    }

    fn is_finished(&self) -> bool {
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::{backend::TestBackend, Terminal};

    fn draw(text: &mut FloatingText<'_>, width: u16, height: u16) -> String {
        let mut terminal = Terminal::new(TestBackend::new(width, height)).unwrap();
        terminal
            .draw(|frame| {
                let area = frame.area();
                text.draw(frame, area, &Theme::Default);
            })
            .unwrap();
        terminal
            .backend()
            .buffer()
            .content
            .iter()
            .map(|cell| cell.symbol())
            .collect()
    }

    #[test]
    fn wrapped_help_end_is_reachable_and_resize_reclamps_scroll() {
        let source = format!("{} LAST_VISIBLE", "word ".repeat(120));
        let mut text = FloatingText::new(source, "Help", true);
        draw(&mut text, 30, 10);
        assert!(text.wrapped_text.lines.len() > 1);
        text.handle_key_event(&KeyEvent::from(KeyCode::End));
        assert!(text.scroll.0 > 0);
        assert!(draw(&mut text, 30, 10).contains("LAST_VISIBLE"));
        draw(&mut text, 200, 30);
        assert_eq!(text.scroll.0, 0);
        text.handle_key_event(&KeyEvent::from(KeyCode::Home));
        assert_eq!(text.scroll, (0, 0));
    }

    #[test]
    fn structured_styles_and_wide_graphemes_survive_wrapping() {
        let text = Text::from(Line::from(vec![
            Span::styled("界界 ", Color::Cyan),
            Span::styled("words", Color::Yellow),
        ]));
        let wrapped = wrapped_text(&text, 4);
        assert!(wrapped.lines.iter().all(|line| line.width() <= 4));
        assert!(wrapped
            .lines
            .iter()
            .flat_map(|line| &line.spans)
            .any(|span| span.style.fg == Some(Color::Yellow)));
        let mut help = FloatingText::from_text(text, "Help", true).with_footer(" Esc to close ");
        for width in 0..8 {
            for height in 0..8 {
                draw(&mut help, width, height);
            }
        }
        assert!(!help.handle_key_event(&KeyEvent::from(KeyCode::Char('J'))));
        assert_eq!(help.scroll, (0, 0));
    }
}

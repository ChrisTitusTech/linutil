use crate::{float::FloatContent, hint::Shortcut, shortcuts, theme::Theme};
use linutil_core::Command;
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, MouseEvent, MouseEventKind},
    prelude::*,
    symbols::border,
    widgets::{Block, Borders, Clear, Paragraph, Wrap},
};
use tree_sitter_bash as hl_bash;
use tree_sitter_highlight::{self as hl, HighlightEvent};

macro_rules! style {
    ($r:literal, $g:literal, $b:literal) => {{
        Style::new().fg(Color::Rgb($r, $g, $b))
    }};
}

const SYNTAX_HIGHLIGHT_STYLES: [(&str, Style); 8] = [
    ("function", style!(220, 220, 170)), // yellow
    ("string", style!(206, 145, 120)),   // brown
    ("property", style!(156, 220, 254)), // light blue
    ("comment", style!(92, 131, 75)),    // green
    ("embedded", style!(206, 145, 120)), // blue (string expansions)
    ("constant", style!(79, 193, 255)),  // dark blue
    ("keyword", style!(197, 134, 192)),  // magenta
    ("number", style!(181, 206, 168)),   // light green
];

pub struct FloatingText<'a> {
    // Width, Height
    inner_area_size: (usize, usize),
    mode_title: String,
    // Cache the text to avoid reprocessing it every frame
    processed_text: Text<'a>,
    // Vertical, Horizontal
    scroll: (u16, u16),
    wrap_words: bool,
}

impl<'a> FloatingText<'a> {
    pub fn new(text: String, title: &str, wrap_words: bool) -> Self {
        let processed_text = Text::from(text);

        Self {
            inner_area_size: (0, 0),
            mode_title: title.to_string(),
            processed_text,
            scroll: (0, 0),
            wrap_words,
        }
    }

    pub fn from_command(command: &Command, title: &str, wrap_words: bool) -> Self {
        let src = match command {
            Command::Raw(cmd) => Some(cmd.clone()),
            Command::LocalFile { file, .. } => std::fs::read_to_string(file)
                .map_err(|_| format!("File not found: {file:?}"))
                .ok(),
            Command::None => None,
        }
        .unwrap();

        let processed_text = Self::get_highlighted_string(&src).unwrap_or_else(|| Text::from(src));

        Self {
            inner_area_size: (0, 0),
            mode_title: title.to_string(),
            processed_text,
            scroll: (0, 0),
            wrap_words,
        }
    }

    fn get_highlighted_string(s: &str) -> Option<Text<'a>> {
        let matched_tokens = SYNTAX_HIGHLIGHT_STYLES
            .iter()
            .map(|hl| hl.0)
            .collect::<Vec<_>>();

        let mut lines = Vec::with_capacity(s.lines().count());
        let mut current_line = Vec::new();
        let mut style_stack = vec![Style::default()];

        let mut hl_conf = hl::HighlightConfiguration::new(
            hl_bash::LANGUAGE.into(),
            "bash",
            hl_bash::HIGHLIGHT_QUERY,
            "",
            "",
        )
        .ok()?;

        hl_conf.configure(&matched_tokens);

        let mut hl = hl::Highlighter::new();
        let events = hl.highlight(&hl_conf, s.as_bytes(), None, |_| None).ok()?;

        for event in events {
            match event.ok()? {
                HighlightEvent::HighlightStart(h) => {
                    style_stack.push(SYNTAX_HIGHLIGHT_STYLES.get(h.0)?.1);
                }

                HighlightEvent::HighlightEnd => {
                    style_stack.pop();
                }

                HighlightEvent::Source { start, end } => {
                    let style = *style_stack.last()?;
                    let content = &s[start..end];

                    for part in content.split_inclusive('\n') {
                        if let Some(stripped) = part.strip_suffix('\n') {
                            // Push the text that is before '\n' and then start a new line
                            // After a new line clear the current line to start a new one
                            current_line.push(Span::styled(stripped.to_owned(), style));
                            lines.push(Line::from(current_line.to_owned()));
                            current_line.clear();
                        } else {
                            current_line.push(Span::styled(part.to_owned(), style));
                        }
                    }
                }
            }
        }

        // Makes sure last line of the file is pushed
        // If no newline at the end of the file we need to push the last line
        if !current_line.is_empty() {
            lines.push(Line::from(current_line));
        }

        if lines.is_empty() {
            return None;
        }

        Some(Text::from(lines))
    }

    fn scroll_down(&mut self) {
        let max_scroll = self
            .processed_text
            .lines
            .len()
            .saturating_sub(self.inner_area_size.1) as u16;
        self.scroll.0 = (self.scroll.0 + 1).min(max_scroll);
    }

    fn scroll_up(&mut self) {
        self.scroll.0 = self.scroll.0.saturating_sub(1);
    }

    fn scroll_left(&mut self) {
        self.scroll.1 = self.scroll.1.saturating_sub(1);
    }

    fn scroll_right(&mut self) {
        let visible_length = self.inner_area_size.0.saturating_sub(1);
        let max_scroll = if self.wrap_words {
            0
        } else {
            self.processed_text
                .lines
                .iter()
                .map(|line| line.width())
                .max()
                .unwrap_or(0)
                .saturating_sub(visible_length) as u16
        };
        self.scroll.1 = (self.scroll.1 + 1).min(max_scroll);
    }
}

impl FloatContent for FloatingText<'_> {
    fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &Theme) {
        let block = Block::default()
            .borders(Borders::ALL)
            .border_set(border::PLAIN)
            .border_style(Style::default().fg(theme.focused_color()))
            .title(self.mode_title.as_str())
            .title_alignment(Alignment::Center)
            .title_style(Style::default().fg(theme.tab_color()).bold())
            .style(Style::default());

        let inner_area = block.inner(area);
        self.inner_area_size = (inner_area.width as usize, inner_area.height as usize);

        frame.render_widget(Clear, area);
        frame.render_widget(block, area);

        let paragraph = if self.wrap_words {
            Paragraph::new(self.processed_text.clone())
                .scroll(self.scroll)
                .wrap(Wrap { trim: false })
        } else {
            Paragraph::new(self.processed_text.clone()).scroll(self.scroll)
        };

        frame.render_widget(paragraph, inner_area);
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
        use KeyCode::{Char, Down, Left, Right, Up};
        match key.code {
            Down | Char('j') | Char('J') => self.scroll_down(),
            Up | Char('k') | Char('K') => self.scroll_up(),
            Left | Char('h') | Char('H') => self.scroll_left(),
            Right | Char('l') | Char('L') => self.scroll_right(),
            _ => {}
        }
        false
    }

    fn is_finished(&self) -> bool {
        true
    }

    fn get_shortcut_list(&self) -> (&str, Box<[Shortcut]>) {
        (
            &self.mode_title,
            shortcuts!(
                ("Scroll down", ["j", "Down"]),
                ("Scroll up", ["k", "Up"]),
                ("Scroll left", ["h", "Left"]),
                ("Scroll right", ["l", "Right"]),
                ("Close window", ["Enter", "p", "q", "d", "g"])
            ),
        )
    }
}

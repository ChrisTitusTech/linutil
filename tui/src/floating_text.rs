use crate::{float::FloatContent, hint::Shortcut, theme::Theme};
use linutil_core::Command;
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, MouseEvent, MouseEventKind},
    prelude::*,
    symbols::border,
    widgets::{Block, Borders, Clear, Paragraph},
};
use tree_sitter_bash as hl_bash;
use tree_sitter_highlight::{self as hl, HighlightEvent};
use unicode_width::UnicodeWidthChar;

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

pub struct FloatingText {
    // Width, Height
    inner_area_size: (usize, usize),
    mode_title: String,
    // Cache the text to avoid reprocessing it every frame
    processed_text: Text<'static>,
    raw_text: String,
    highlighted_text: Option<Text<'static>>,
    syntax_highlight: bool,
    // Vertical, Horizontal
    scroll: (u16, u16),
    wrap_words: bool,
    last_layout: Option<(usize, bool, bool)>,
}

impl FloatingText {
    pub fn new(text: String, title: &str, wrap_words: bool) -> Self {
        let processed_text = Text::from(text.clone());

        Self {
            inner_area_size: (0, 0),
            mode_title: title.to_string(),
            processed_text,
            raw_text: text,
            highlighted_text: None,
            syntax_highlight: false,
            scroll: (0, 0),
            wrap_words,
            last_layout: None,
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

        let src = Self::expand_tabs(&src, 4);
        let highlighted_text = Self::get_highlighted_string(&src);
        let processed_text = highlighted_text
            .clone()
            .unwrap_or_else(|| Text::from(src.clone()));

        Self {
            inner_area_size: (0, 0),
            mode_title: title.to_string(),
            processed_text,
            raw_text: src,
            highlighted_text,
            syntax_highlight: true,
            scroll: (0, 0),
            wrap_words,
            last_layout: None,
        }
    }

    fn get_highlighted_string(s: &str) -> Option<Text<'static>> {
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

    fn expand_tabs(s: &str, tab_width: usize) -> String {
        let mut out = String::with_capacity(s.len());
        let mut col = 0usize;
        for ch in s.chars() {
            if ch == '\t' {
                let spaces = tab_width.saturating_sub(col % tab_width).max(1);
                out.extend(std::iter::repeat_n(' ', spaces));
                col = col.saturating_add(spaces);
                continue;
            }
            out.push(ch);
            col = col.saturating_add(UnicodeWidthChar::width(ch).unwrap_or(0).max(1));
            if ch == '\n' {
                col = 0;
            }
        }
        out
    }

    fn split_at_width(s: &str, width: usize) -> usize {
        if width == 0 {
            return 0;
        }
        let mut used = 0usize;
        let mut last_idx = 0usize;
        for (idx, ch) in s.char_indices() {
            let ch_width = UnicodeWidthChar::width(ch).unwrap_or(0).max(1);
            if used.saturating_add(ch_width) > width {
                break;
            }
            used = used.saturating_add(ch_width);
            last_idx = idx + ch.len_utf8();
        }
        last_idx
    }

    fn str_width(s: &str) -> usize {
        s.chars()
            .map(|ch| UnicodeWidthChar::width(ch).unwrap_or(0).max(1))
            .sum()
    }

    fn wrap_plain_text(s: &str, width: usize) -> Text<'static> {
        let mut lines = Vec::new();
        for line in s.split('\n') {
            if line.is_empty() {
                lines.push(Line::from(""));
                continue;
            }
            let mut remaining = line;
            while !remaining.is_empty() {
                let mut split = Self::split_at_width(remaining, width);
                if split == 0 {
                    let ch = remaining.chars().next().unwrap();
                    split = ch.len_utf8();
                }
                let (head, tail) = remaining.split_at(split);
                lines.push(Line::from(head.to_string()));
                remaining = tail;
            }
        }
        Text::from(lines)
    }

    fn wrap_highlighted_text(text: &Text<'static>, width: usize) -> Text<'static> {
        if width == 0 {
            return Text::from("");
        }

        let mut lines: Vec<Line<'static>> = Vec::new();
        for line in &text.lines {
            if line.spans.is_empty() {
                lines.push(Line::from(""));
                continue;
            }

            let mut current: Vec<Span<'static>> = Vec::new();
            let mut current_width = 0usize;

            for span in &line.spans {
                let style = span.style;
                let mut content = span.content.as_ref();

                while !content.is_empty() {
                    let remaining = width.saturating_sub(current_width);
                    if remaining == 0 {
                        lines.push(Line::from(std::mem::take(&mut current)));
                        current_width = 0;
                        continue;
                    }

                    let mut split = Self::split_at_width(content, remaining);
                    if split == 0 {
                        let ch = content.chars().next().unwrap();
                        split = ch.len_utf8();
                    }

                    let (head, tail) = content.split_at(split);
                    if !head.is_empty() {
                        current.push(Span::styled(head.to_string(), style));
                        current_width = current_width.saturating_add(Self::str_width(head));
                    }
                    content = tail;

                    if current_width >= width {
                        lines.push(Line::from(std::mem::take(&mut current)));
                        current_width = 0;
                    }
                }
            }

            if !current.is_empty() {
                lines.push(Line::from(current));
            }
        }

        Text::from(lines)
    }

    fn refresh_processed_text(&mut self, width: usize) {
        let key = (width, self.wrap_words, self.syntax_highlight);
        if self.last_layout == Some(key) {
            return;
        }
        self.last_layout = Some(key);

        if self.wrap_words {
            self.scroll.1 = 0;
            self.processed_text = if self.syntax_highlight {
                if let Some(highlighted) = &self.highlighted_text {
                    Self::wrap_highlighted_text(highlighted, width)
                } else {
                    Self::wrap_plain_text(&self.raw_text, width)
                }
            } else {
                Self::wrap_plain_text(&self.raw_text, width)
            };
        } else if self.syntax_highlight {
            self.processed_text = self
                .highlighted_text
                .clone()
                .unwrap_or_else(|| Text::from(self.raw_text.clone()));
        } else {
            self.processed_text = Text::from(self.raw_text.clone());
        }
    }

    fn clamp_scroll(&mut self) {
        let max_scroll = self
            .processed_text
            .lines
            .len()
            .saturating_sub(self.inner_area_size.1) as u16;
        self.scroll.0 = self.scroll.0.min(max_scroll);
        if self.wrap_words {
            self.scroll.1 = 0;
        }
    }
}

impl FloatContent for FloatingText {
    fn draw(&mut self, frame: &mut Frame, area: Rect, theme: &Theme) {
        let title = self.mode_title.clone();
        let block = Block::default()
            .borders(Borders::ALL)
            .border_set(border::PLAIN)
            .border_style(Style::default().fg(theme.focused_color()))
            .title(title)
            .title_alignment(Alignment::Center)
            .title_style(Style::default().fg(theme.tab_color()).bold())
            .style(Style::default());

        let inner_area = block.inner(area);
        self.inner_area_size = (inner_area.width as usize, inner_area.height as usize);
        self.refresh_processed_text(inner_area.width as usize);
        self.clamp_scroll();

        frame.render_widget(Clear, area);
        frame.render_widget(block, area);

        let paragraph = Paragraph::new(self.processed_text.clone()).scroll(self.scroll);

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
        let mut shortcuts = vec![
            Shortcut::new("Scroll down", ["j", "Down"]),
            Shortcut::new("Scroll up", ["k", "Up"]),
            Shortcut::new("Scroll left", ["h", "Left"]),
            Shortcut::new("Scroll right", ["l", "Right"]),
        ];
        shortcuts.push(Shortcut::new("Close window", ["Enter", "q"]));
        (&self.mode_title, shortcuts.into_boxed_slice())
    }
}

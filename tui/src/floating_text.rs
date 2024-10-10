use std::{
    borrow::Cow,
    collections::VecDeque,
    io::{Cursor, Read as _, Seek, SeekFrom, Write as _},
};

use crate::{float::FloatContent, hint::Shortcut};

use linutil_core::Command;

use crossterm::event::{KeyCode, KeyEvent};

use ratatui::{
    layout::Rect,
    style::{Style, Stylize},
    text::Line,
    widgets::{Block, Borders, Clear, List},
    Frame,
};

use ansi_to_tui::IntoText;

use tree_sitter_bash as hl_bash;
use tree_sitter_highlight::{self as hl, HighlightEvent};
use zips::zip_result;

pub struct FloatingText {
    pub src: Vec<String>,
    max_line_width: usize,
    v_scroll: usize,
    h_scroll: usize,
    mode_title: String,
}

macro_rules! style {
    ($r:literal, $g:literal, $b:literal) => {{
        use anstyle::{Color, RgbColor, Style};
        Style::new().fg_color(Some(Color::Rgb(RgbColor($r, $g, $b))))
    }};
}

const SYNTAX_HIGHLIGHT_STYLES: [(&str, anstyle::Style); 8] = [
    ("function", style!(220, 220, 170)), // yellow
    ("string", style!(206, 145, 120)),   // brown
    ("property", style!(156, 220, 254)), // light blue
    ("comment", style!(92, 131, 75)),    // green
    ("embedded", style!(206, 145, 120)), // blue (string expansions)
    ("constant", style!(79, 193, 255)),  // dark blue
    ("keyword", style!(197, 134, 192)),  // magenta
    ("number", style!(181, 206, 168)),   // light green
];

fn get_highlighted_string(s: &str) -> Option<String> {
    let mut hl_conf = hl::HighlightConfiguration::new(
        hl_bash::LANGUAGE.into(),
        "bash",
        hl_bash::HIGHLIGHT_QUERY,
        "",
        "",
    )
    .ok()?;

    let matched_tokens = &SYNTAX_HIGHLIGHT_STYLES
        .iter()
        .map(|hl| hl.0)
        .collect::<Vec<_>>();

    hl_conf.configure(matched_tokens);

    let mut hl = hl::Highlighter::new();

    let mut style_stack = vec![anstyle::Style::new()];
    let src = s.as_bytes();

    let events = hl.highlight(&hl_conf, src, None, |_| None).ok()?;

    let mut buf = Cursor::new(vec![]);

    for event in events {
        match event.unwrap() {
            HighlightEvent::HighlightStart(h) => {
                style_stack.push(SYNTAX_HIGHLIGHT_STYLES.get(h.0)?.1);
            }

            HighlightEvent::HighlightEnd => {
                style_stack.pop();
            }

            HighlightEvent::Source { start, end } => {
                let style = style_stack.last()?;
                zip_result!(
                    write!(&mut buf, "{}", style),
                    buf.write_all(&src[start..end]),
                    write!(&mut buf, "{style:#}"),
                )?;
            }
        }
    }

    let mut output = String::new();

    zip_result!(
        buf.seek(SeekFrom::Start(0)),
        buf.read_to_string(&mut output),
    )?;

    Some(output)
}

macro_rules! max_width {
    ($($lines:tt)+) => {{
        $($lines)+.iter().fold(0, |accum, val| accum.max(val.len()))
    }}
}

#[inline]
fn get_lines(s: &str) -> Vec<&str> {
    s.lines().collect::<Vec<_>>()
}

#[inline]
fn get_lines_owned(s: &str) -> Vec<String> {
    get_lines(s).iter().map(|s| s.to_string()).collect()
}

impl FloatingText {
    pub fn new(text: String, title: &str) -> Self {
        let src = get_lines(&text)
            .into_iter()
            .map(|s| s.to_string())
            .collect::<Vec<_>>();

        let max_line_width = max_width!(src);
        Self {
            src,
            mode_title: title.to_string(),
            max_line_width,
            v_scroll: 0,
            h_scroll: 0,
        }
    }

    pub fn from_command(command: &Command, title: String) -> Option<Self> {
        let (max_line_width, src) = match command {
            Command::Raw(cmd) => {
                // just apply highlights directly
                (max_width!(get_lines(cmd)), Some(cmd.clone()))
            }
            Command::LocalFile { file, .. } => {
                // have to read from tmp dir to get cmd src
                let raw = std::fs::read_to_string(file)
                    .map_err(|_| format!("File not found: {:?}", file))
                    .unwrap();

                (max_width!(get_lines(&raw)), Some(raw))
            }

            // If command is a folder, we don't display a preview
            Command::None => (0usize, None),
        };

        let src = get_lines_owned(&get_highlighted_string(&src?)?);

        Some(Self {
            src,
            mode_title: title,
            max_line_width,
            h_scroll: 0,
            v_scroll: 0,
        })
    }

    fn scroll_down(&mut self) {
        if self.v_scroll + 1 < self.src.len() {
            self.v_scroll += 1;
        }
    }

    fn scroll_up(&mut self) {
        if self.v_scroll > 0 {
            self.v_scroll -= 1;
        }
    }

    fn scroll_left(&mut self) {
        if self.h_scroll > 0 {
            self.h_scroll -= 1;
        }
    }

    fn scroll_right(&mut self) {
        if self.h_scroll + 1 < self.max_line_width {
            self.h_scroll += 1;
        }
    }
}

impl FloatContent for FloatingText {
    fn draw(&mut self, frame: &mut Frame, area: Rect) {
        // Define the Block with a border and background color
        let block = Block::default()
            .borders(Borders::ALL)
            .title(self.mode_title.clone())
            .title_alignment(ratatui::layout::Alignment::Center)
            .title_style(Style::default().reversed())
            .style(Style::default());

        // Draw the Block first
        frame.render_widget(block.clone(), area);

        // Calculate the inner area to ensure text is not drawn over the border
        let inner_area = block.inner(area);
        let Rect { height, .. } = inner_area;
        let lines = self
            .src
            .iter()
            .skip(self.v_scroll)
            .take(height as usize)
            .flat_map(|l| l.into_text().unwrap())
            .map(|line| {
                let mut skipped = 0;
                let mut spans = line
                    .into_iter()
                    .skip_while(|span| {
                        let skip = (skipped + span.content.len()) <= self.h_scroll;
                        if skip {
                            skipped += span.content.len();
                            true
                        } else {
                            false
                        }
                    })
                    .collect::<VecDeque<_>>();

                if spans.is_empty() {
                    Line::raw(Cow::Owned(String::new()))
                } else {
                    if skipped < self.h_scroll {
                        let to_split = spans.pop_front().unwrap();
                        let new_content = to_split.content.clone().into_owned()
                            [self.h_scroll - skipped..]
                            .to_owned();
                        spans.push_front(to_split.content(Cow::Owned(new_content)));
                    }

                    Line::from(Vec::from(spans))
                }
            })
            .collect::<Vec<_>>();

        // Create list widget
        let list = List::new(lines)
            .block(Block::default())
            .highlight_style(Style::default().reversed());

        // Clear the text underneath the floats rendered area
        frame.render_widget(Clear, inner_area);

        // Render the list inside the bordered area
        frame.render_widget(list, inner_area);
    }

    fn handle_key_event(&mut self, key: &KeyEvent) -> bool {
        use KeyCode::*;
        match key.code {
            Down | Char('j') => self.scroll_down(),
            Up | Char('k') => self.scroll_up(),
            Left | Char('h') => self.scroll_left(),
            Right | Char('l') => self.scroll_right(),
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
            Box::new([
                Shortcut::new("Scroll down", ["j", "Down"]),
                Shortcut::new("Scroll up", ["k", "Up"]),
                Shortcut::new("Scroll left", ["h", "Left"]),
                Shortcut::new("Scroll right", ["l", "Right"]),
                Shortcut::new("Close window", ["Enter", "p", "q", "d", "g"]),
            ]),
        )
    }
}

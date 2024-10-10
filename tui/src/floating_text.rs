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

use textwrap::wrap;
use tree_sitter_bash as hl_bash;
use tree_sitter_highlight::{self as hl, HighlightEvent};
use zips::zip_result;

#[derive(Clone)]
pub enum FloatingTextMode {
    Preview,
    Description,
    ActionsGuide,
}

pub struct FloatingText {
    pub src: String,
    wrapped_lines: Vec<String>,
    max_line_width: usize,
    v_scroll: usize,
    h_scroll: usize,
    mode_title: String,
    mode: FloatingTextMode,
}

macro_rules! style {
    ($r:literal, $g:literal, $b:literal) => {{
        use anstyle::{Color, RgbColor, Style};
        Style::new().fg_color(Some(Color::Rgb(RgbColor($r, $g, $b))))
    }};
}

const SYNTAX_HIGHLIGHT_STYLES: [(&str, anstyle::Style); 8] = [
    ("function", style!(220, 220, 170)),
    ("string", style!(206, 145, 120)),
    ("property", style!(156, 220, 254)),
    ("comment", style!(92, 131, 75)),
    ("embedded", style!(206, 145, 120)),
    ("constant", style!(79, 193, 255)),
    ("keyword", style!(197, 134, 192)),
    ("number", style!(181, 206, 168)),
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

#[inline]
fn get_lines(s: &str) -> Vec<&str> {
    s.lines().collect::<Vec<_>>()
}

#[inline]
fn get_lines_owned(s: &str) -> Vec<String> {
    get_lines(s).iter().map(|s| s.to_string()).collect()
}

impl FloatingText {
    pub fn new(text: String, mode: FloatingTextMode) -> Self {
        let max_line_width = 80;
        let wrapped_lines = wrap(&text, max_line_width)
            .into_iter()
            .map(|cow| cow.into_owned())
            .collect();
        Self {
            src: text,
            wrapped_lines,
            mode_title: Self::get_mode_title(&mode).to_string(),
            max_line_width,
            v_scroll: 0,
            h_scroll: 0,
            mode,
        }
    }

    pub fn from_command(command: &Command, mode: FloatingTextMode) -> Option<Self> {
        let src = match command {
            Command::Raw(cmd) => Some(cmd.clone()),
            Command::LocalFile { file, .. } => std::fs::read_to_string(file)
                .map_err(|_| format!("File not found: {:?}", file))
                .ok(),
            Command::None => None,
        }?;

        let max_line_width = 80;
        let wrapped_lines = match mode {
            FloatingTextMode::Description => wrap(&src, max_line_width)
                .into_iter()
                .map(|cow| cow.into_owned())
                .collect(),
            _ => get_lines_owned(&get_highlighted_string(&src)?),
        };

        Some(Self {
            src,
            wrapped_lines,
            mode_title: Self::get_mode_title(&mode).to_string(),
            max_line_width,
            h_scroll: 0,
            v_scroll: 0,
            mode,
        })
    }

    fn get_mode_title(mode: &FloatingTextMode) -> &'static str {
        match mode {
            FloatingTextMode::Preview => "Command Preview",
            FloatingTextMode::Description => "Command Description",
            FloatingTextMode::ActionsGuide => "Important Actions Guide",
        }
    }

    fn scroll_down(&mut self) {
        if self.v_scroll + 1 < self.wrapped_lines.len() {
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

    fn update_wrapping(&mut self, width: usize) {
        if self.max_line_width != width {
            self.max_line_width = width;
            self.wrapped_lines = match self.mode {
                FloatingTextMode::Description => wrap(&self.src, width)
                    .into_iter()
                    .map(|cow| cow.into_owned())
                    .collect(),
                _ => {
                    get_lines_owned(&get_highlighted_string(&self.src).unwrap_or(self.src.clone()))
                }
            };
        }
    }
}

impl FloatContent for FloatingText {
    fn draw(&mut self, frame: &mut Frame, area: Rect) {
        let block = Block::default()
            .borders(Borders::ALL)
            .title(self.mode_title.clone())
            .title_alignment(ratatui::layout::Alignment::Center)
            .title_style(Style::default().reversed())
            .style(Style::default());

        frame.render_widget(block.clone(), area);

        let inner_area = block.inner(area);
        let Rect { width, height, .. } = inner_area;

        self.update_wrapping(width as usize);

        let lines = self
            .wrapped_lines
            .iter()
            .skip(self.v_scroll)
            .take(height as usize)
            .flat_map(|l| {
                if let FloatingTextMode::Description = self.mode {
                    vec![Line::raw(l.clone())]
                } else {
                    l.into_text().unwrap().lines
                }
            })
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

        let list = List::new(lines)
            .block(Block::default())
            .highlight_style(Style::default().reversed());

        frame.render_widget(Clear, inner_area);
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
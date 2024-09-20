use std::io::{Cursor, Read as _, Seek, SeekFrom, Write as _};

use crate::{
    float::FloatContent,
    hint::{Shortcut, ShortcutList},
};

use linutil_core::Command;

use crossterm::event::{KeyCode, KeyEvent};

use ratatui::{
    layout::Rect,
    style::{Style, Stylize},
    widgets::{Block, Borders, Clear, List},
    Frame,
};

use ansi_to_tui::IntoText;

use tree_sitter_bash as hl_bash;
use tree_sitter_highlight::{self as hl, HighlightEvent};
use zips::zip_result;

pub enum FloatingTextMode {
    Preview,
    Description,
}

pub struct FloatingText {
    src: String,
    scroll: usize,
    n_lines: usize,
    mode: FloatingTextMode,
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

impl FloatingText {
    pub fn new(text: String, mode: FloatingTextMode) -> Self {
        let mut n_lines = 0;

        text.split("\n").for_each(|_| n_lines += 1);

        Self {
            src: text,
            scroll: 0,
            n_lines,
            mode,
        }
    }

    pub fn from_command(command: &Command, mode: FloatingTextMode) -> Option<Self> {
        let src = match command {
            Command::Raw(cmd) => {
                // just apply highlights directly
                get_highlighted_string(cmd)
            }

            Command::LocalFile(file_path) => {
                // have to read from tmp dir to get cmd src
                let file_contents = std::fs::read_to_string(file_path)
                    .map_err(|_| format!("File not found: {:?}", file_path))
                    .unwrap();

                get_highlighted_string(&file_contents)
            }

            // If command is a folder, we don't display a preview
            Command::None => None,
        };

        Some(Self::new(src?, mode))
    }

    fn scroll_down(&mut self) {
        if self.scroll + 1 < self.n_lines {
            self.scroll += 1;
        }
    }

    fn scroll_up(&mut self) {
        if self.scroll > 0 {
            self.scroll -= 1;
        }
    }
}

impl FloatContent for FloatingText {
    fn draw(&mut self, frame: &mut Frame, area: Rect) {
        // Define the Block with a border and background color
        let block_title = match self.mode {
            FloatingTextMode::Preview => "Command Preview",
            FloatingTextMode::Description => "Command Description",
        };

        let block = Block::default()
            .borders(Borders::ALL)
            .title(block_title)
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
            .lines()
            .skip(self.scroll)
            .take(height as usize)
            .map(|l| l.into_text().unwrap())
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
        match key.code {
            KeyCode::Down | KeyCode::Char('j') => self.scroll_down(),
            KeyCode::Up | KeyCode::Char('k') => self.scroll_up(),
            _ => {}
        }
        false
    }

    fn is_finished(&self) -> bool {
        true
    }

    fn get_shortcut_list(&self) -> ShortcutList {
        ShortcutList {
            scope_name: "Floating text",
            hints: vec![
                Shortcut::new(vec!["j", "Down"], "Scroll down"),
                Shortcut::new(vec!["k", "Up"], "Scroll up"),
                Shortcut::new(vec!["Enter", "q"], "Close window"),
            ],
        }
    }
}

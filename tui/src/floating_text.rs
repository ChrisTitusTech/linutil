use crate::{
    float::FloatContent,
    hint::{Shortcut, ShortcutList},
};
use crossterm::event::{KeyCode, KeyEvent};
use linutil_core::Command;
use ratatui::{
    layout::Rect,
    style::{Style, Stylize},
    text::Line,
    widgets::{Block, Borders, Clear, List},
    Frame,
};
pub enum FloatingTextMode {
    Preview,
    Description,
}
pub struct FloatingText {
    text: Vec<String>,
    mode: FloatingTextMode,
    scroll: usize,
}

impl FloatingText {
    pub fn new(text: Vec<String>, mode: FloatingTextMode) -> Self {
        Self {
            text,
            scroll: 0,
            mode,
        }
    }

    pub fn from_command(command: &Command, mode: FloatingTextMode) -> Option<Self> {
        let lines = match command {
            Command::Raw(cmd) => {
                // Reconstruct the line breaks and file formatting after the
                // 'include_str!()' call in the node
                cmd.lines().map(|line| line.to_string()).collect()
            }
            Command::LocalFile(file_path) => {
                let file_contents = std::fs::read_to_string(file_path)
                    .map_err(|_| format!("File not found: {:?}", file_path))
                    .unwrap();
                file_contents.lines().map(|line| line.to_string()).collect()
            }
            // If command is a folder, we don't display a preview
            Command::None => return None,
        };
        Some(Self::new(lines, mode))
    }

    fn scroll_down(&mut self) {
        if self.scroll + 1 < self.text.len() {
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

        // Create the list of lines to be displayed
        let lines: Vec<Line> = self
            .text
            .iter()
            .skip(self.scroll)
            .flat_map(|line| {
                if line.is_empty() {
                    return vec![String::new()];
                }
                line.chars()
                    .collect::<Vec<char>>()
                    .chunks(inner_area.width as usize)
                    .map(|chunk| chunk.iter().collect())
                    .collect::<Vec<String>>()
            })
            .take(inner_area.height as usize)
            .map(Line::from)
            .collect();

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

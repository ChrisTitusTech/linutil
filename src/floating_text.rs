use crate::{float::FloatContent, running_command::Command};
use crossterm::event::{KeyCode, KeyEvent};
use ratatui::{
    layout::Rect,
    style::{Style, Stylize},
    text::Line,
    widgets::{Block, Borders, List},
    Frame,
};

pub struct FloatingText {
    text: Vec<String>,
    scroll: usize,
}

impl FloatingText {
    pub fn new(text: Vec<String>) -> Self {
        Self { text, scroll: 0 }
    }

    pub fn from_command(command: &Command) -> Option<Self> {
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
        Some(Self::new(lines))
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
        let block = Block::default()
            .borders(Borders::ALL)
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
}

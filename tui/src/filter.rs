use crate::{state::ListEntry, theme::Theme};
use linutil_core::{ego_tree::NodeId, Tab};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, KeyModifiers},
    prelude::*,
    symbols::border,
    widgets::{Block, Paragraph},
};
use unicode_width::UnicodeWidthChar;

pub enum SearchAction {
    None,
    Exit,
    Update,
}

pub struct Filter {
    // Use Vec<char> to handle multi-byte characters like emojis
    search_input: Vec<char>,
    in_search_mode: bool,
    input_position: usize,
    items: Vec<ListEntry>,
    // No complex string manipulation is done with completion so we can use String unlike search_input
    completion: Option<String>,
}

impl Filter {
    pub fn new() -> Self {
        Self {
            search_input: vec![],
            in_search_mode: false,
            input_position: 0,
            items: vec![],
            completion: None,
        }
    }

    pub fn item_list(&self) -> &[ListEntry] {
        &self.items
    }

    pub fn activate_search(&mut self) {
        self.in_search_mode = true;
    }

    pub fn deactivate_search(&mut self) {
        self.in_search_mode = false;
        self.completion = None;
    }

    pub fn update_items(&mut self, tabs: &[Tab], current_tab: usize, node: NodeId) {
        if self.search_input.is_empty() {
            let curr = tabs[current_tab].tree.get(node).unwrap();

            self.items = curr
                .children()
                .map(|node| ListEntry {
                    node: node.value().clone(),
                    id: node.id(),
                    has_children: node.has_children(),
                })
                .collect();
        } else {
            self.items.clear();
            let query_lower = self.search_input.iter().collect::<String>().to_lowercase();
            for tab in tabs {
                let mut stack = vec![tab.tree.root().id()];
                while let Some(node_id) = stack.pop() {
                    let node = tab.tree.get(node_id).unwrap();
                    if node.value().name.to_lowercase().contains(&query_lower)
                        && !node.has_children()
                    {
                        self.items.push(ListEntry {
                            node: node.value().clone(),
                            id: node.id(),
                            has_children: false,
                        });
                    }
                    stack.extend(node.children().map(|child| child.id()));
                }
            }
            self.items
                .sort_unstable_by(|a, b| a.node.name.cmp(&b.node.name));
        }
        self.update_completion();
    }

    fn update_completion(&mut self) {
        self.completion = if self.items.is_empty() || self.search_input.is_empty() {
            None
        } else {
            self.items.iter().find_map(|item| {
                let mut item_chars = item.node.name.chars();
                let mut search_chars = self.search_input.iter();
                loop {
                    // Take the next character from search input first, since we don't want to remove an extra character from the item
                    let Some(search_char) = search_chars.next() else {
                        break;
                    };

                    // If the item is shorter than the search input, or a character doesn't match, skip this item
                    let item_char = item_chars.next()?;
                    if !item_char.eq_ignore_ascii_case(search_char) {
                        return None;
                    }
                }
                Some(
                    item_chars
                        .map(|c| c.to_ascii_lowercase())
                        .collect::<String>(),
                )
            })
        }
    }

    pub fn draw_searchbar(&self, frame: &mut Frame, area: Rect, theme: &Theme) {
        //Set the search bar text (If empty use the placeholder)
        let display_text = if !self.in_search_mode && self.search_input.is_empty() {
            Span::raw("Press / to search")
        } else {
            let input_text = self.search_input.iter().collect::<String>();
            Span::styled(input_text, Style::default().fg(theme.focused_color()))
        };

        let search_color = if self.in_search_mode {
            theme.focused_color()
        } else {
            theme.unfocused_color()
        };

        //Create the search bar widget
        let search_bar = Paragraph::new(display_text)
            .block(
                Block::bordered()
                    .border_set(border::ROUNDED)
                    .title(" Search "),
            )
            .style(Style::default().fg(search_color));

        //Render the search bar (First chunk of the screen)
        frame.render_widget(search_bar, area);

        // Render cursor in search bar
        if self.in_search_mode {
            // Calculate the visual width of search input so that completion preview can be displayed after the search input
            let search_input_size: u16 = self
                .search_input
                .iter()
                .map(|c| c.width().unwrap_or(1) as u16)
                .sum();

            let cursor_position: u16 = self.search_input[..self.input_position]
                .iter()
                .map(|c| c.width().unwrap_or(1) as u16)
                .sum();
            let x = area.x + cursor_position + 1;
            let y = area.y + 1;
            frame.set_cursor_position(Position::new(x, y));

            if let Some(preview) = &self.completion {
                let preview_x = area.x + search_input_size + 1;
                let preview_span =
                    Span::styled(preview, Style::default().fg(theme.search_preview_color()));
                let preview_area = Rect::new(
                    preview_x,
                    y,
                    (preview.len() as u16).min(area.width - search_input_size - 1), // Ensure the completion preview stays within the search bar bounds
                    1,
                );
                frame.render_widget(Paragraph::new(preview_span), preview_area);
            }
        }
    }
    // Handles key events. Returns true if search must be exited
    pub fn handle_key(&mut self, event: &KeyEvent) -> SearchAction {
        match event.code {
            KeyCode::Char('c') if event.modifiers.contains(KeyModifiers::CONTROL) => {
                return self.exit_search()
            }
            KeyCode::Char(c) => self.insert_char(c),
            KeyCode::Backspace => self.remove_previous(),
            KeyCode::Delete => self.remove_next(),
            KeyCode::Left => return self.cursor_left(),
            KeyCode::Right => return self.cursor_right(),
            KeyCode::Tab => return self.complete_search(),
            KeyCode::Esc => {
                self.input_position = 0;
                self.search_input.clear();
                self.completion = None;
                return SearchAction::Exit;
            }
            KeyCode::Enter => return SearchAction::Exit,
            _ => return SearchAction::None,
        };
        self.update_completion();
        SearchAction::Update
    }

    fn exit_search(&mut self) -> SearchAction {
        self.input_position = 0;
        self.search_input.clear();
        SearchAction::Exit
    }

    fn cursor_left(&mut self) -> SearchAction {
        self.input_position = self.input_position.saturating_sub(1);
        SearchAction::None
    }

    fn cursor_right(&mut self) -> SearchAction {
        if self.input_position < self.search_input.len() {
            self.input_position += 1;
        }
        SearchAction::None
    }

    fn insert_char(&mut self, input: char) {
        self.search_input.insert(self.input_position, input);
        self.cursor_right();
    }

    fn remove_previous(&mut self) {
        let current = self.input_position;
        if current > 0 {
            self.search_input.remove(current - 1);
            self.cursor_left();
        }
    }

    fn remove_next(&mut self) {
        let current = self.input_position;
        if current < self.search_input.len() {
            self.search_input.remove(current);
        }
    }

    fn complete_search(&mut self) -> SearchAction {
        if let Some(completion) = &self.completion {
            self.search_input.extend(completion.chars());
            self.input_position = self.search_input.len();
            self.completion = None;
            SearchAction::Update
        } else {
            SearchAction::None
        }
    }

    pub fn clear_search(&mut self) {
        self.search_input.clear();
        self.input_position = 0;
    }
}

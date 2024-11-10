use crate::{state::ListEntry, theme::Theme};
use linutil_core::{ego_tree::NodeId, Tab};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, KeyModifiers},
    layout::{Position, Rect},
    style::Style,
    text::Span,
    widgets::{Block, Borders, Paragraph},
    Frame,
};
use regex::RegexBuilder;

pub enum SearchAction {
    None,
    Exit,
    Update,
}

pub struct Filter {
    search_input: String,
    in_search_mode: bool,
    input_position: usize,
    items: Vec<ListEntry>,
    completion_preview: Option<String>,
}

impl Filter {
    pub fn new() -> Self {
        Self {
            search_input: String::new(),
            in_search_mode: false,
            input_position: 0,
            items: vec![],
            completion_preview: None,
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
        self.completion_preview = None;
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
            if let Ok(regex) = self.regex_builder(&regex::escape(&self.search_input)) {
                for tab in tabs {
                    let mut stack = vec![tab.tree.root().id()];
                    while let Some(node_id) = stack.pop() {
                        let node = tab.tree.get(node_id).unwrap();
                        if regex.is_match(&node.value().name) && !node.has_children() {
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
            } else {
                self.search_input.clear();
            }
        }
        self.update_completion_preview();
    }

    fn update_completion_preview(&mut self) {
        self.completion_preview = if self.items.is_empty() || self.search_input.is_empty() {
            None
        } else {
            let pattern = format!("(?i)^{}", regex::escape(&self.search_input));
            if let Ok(regex) = self.regex_builder(&pattern) {
                self.items.iter().find_map(|item| {
                    regex
                        .find(&item.node.name)
                        .map(|mat| item.node.name[mat.end()..].to_string())
                })
            } else {
                None
            }
        }
    }

    pub fn draw_searchbar(&self, frame: &mut Frame, area: Rect, theme: &Theme) {
        //Set the search bar text (If empty use the placeholder)
        let display_text = if !self.in_search_mode && self.search_input.is_empty() {
            Span::raw("Press / to search")
        } else {
            Span::styled(
                &self.search_input,
                Style::default().fg(theme.focused_color()),
            )
        };

        let search_color = if self.in_search_mode {
            theme.focused_color()
        } else {
            theme.unfocused_color()
        };

        //Create the search bar widget
        let search_bar = Paragraph::new(display_text)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_set(ratatui::symbols::border::ROUNDED)
                    .title(" Search "),
            )
            .style(Style::default().fg(search_color));

        //Render the search bar (First chunk of the screen)
        frame.render_widget(search_bar, area);

        // Render cursor in search bar
        if self.in_search_mode {
            let x = area.x + self.input_position as u16 + 1;
            let y = area.y + 1;
            frame.set_cursor_position(Position::new(x, y));

            if let Some(preview) = &self.completion_preview {
                let preview_x = area.x + self.search_input.len() as u16 + 1;
                let preview_span =
                    Span::styled(preview, Style::default().fg(theme.search_preview_color()));
                let preview_area = Rect::new(preview_x, y, preview.len() as u16, 1);
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
                self.completion_preview = None;
                return SearchAction::Exit;
            }
            KeyCode::Enter => return SearchAction::Exit,
            _ => return SearchAction::None,
        };
        self.update_completion_preview();
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

    fn regex_builder(&self, pattern: &str) -> Result<regex::Regex, regex::Error> {
        RegexBuilder::new(pattern).case_insensitive(true).build()
    }

    fn complete_search(&mut self) -> SearchAction {
        if self.completion_preview.is_none() {
            SearchAction::None
        } else {
            let pattern = format!("(?i)^{}", self.search_input);
            if let Ok(regex) = self.regex_builder(&pattern) {
                self.search_input = self
                    .items
                    .iter()
                    .find_map(|item| {
                        if regex.is_match(&item.node.name) {
                            Some(item.node.name.clone())
                        } else {
                            None
                        }
                    })
                    .unwrap_or_default();

                self.completion_preview = None;
                self.input_position = self.search_input.len();

                SearchAction::Update
            } else {
                SearchAction::None
            }
        }
    }

    pub fn clear_search(&mut self) {
        self.search_input.clear();
        self.input_position = 0;
    }
}

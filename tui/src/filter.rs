use crate::{state::ListEntry, theme::Theme};
use linutil_core::{ego_tree::NodeId, Tab};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, KeyModifiers},
    prelude::*,
    widgets::Paragraph,
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
                let search_chars = self.search_input.iter();
                for search_char in search_chars {
                    // Take the next character from search input first, since we don't want to remove an extra character from the item
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

    pub fn is_filtered(&self) -> bool {
        !self.search_input.is_empty()
    }

    /// Draw the search control into the dashboard's single-line header.
    pub fn draw_searchbar(&self, frame: &mut Frame, area: Rect, theme: &Theme) {
        let area = area.intersection(frame.area());
        if area.is_empty() {
            return;
        }
        let area = Rect::new(area.x, area.y, area.width, 1);
        let color = if self.in_search_mode {
            theme.focused_color()
        } else {
            theme.muted()
        };
        if !self.in_search_mode && self.search_input.is_empty() {
            frame.render_widget(
                Paragraph::new("/ Search").style(Style::default().fg(color)),
                area,
            );
            return;
        }

        // Keep the slash visible while scrolling the input by character boundaries.
        // Reserve one cell for the cursor, including when it follows a wide glyph.
        let input_width = area.width.saturating_sub(2) as usize;
        let cursor_index = if self.in_search_mode {
            self.input_position.min(self.search_input.len())
        } else {
            self.search_input.len()
        };
        let cell_width = |c: &char| c.width().unwrap_or(0);
        let mut start = 0;
        let mut cursor_column: usize = self.search_input[..cursor_index]
            .iter()
            .map(cell_width)
            .sum();
        while start < cursor_index && cursor_column >= input_width {
            cursor_column = cursor_column.saturating_sub(cell_width(&self.search_input[start]));
            start += 1;
        }
        let mut input = String::new();
        let mut used_width = 0;
        let mut end = start;
        for c in &self.search_input[start..] {
            let width = cell_width(c);
            if used_width + width > input_width {
                break;
            }
            input.push(*c);
            used_width += width;
            end += 1;
        }
        let mut spans = vec![Span::styled(
            format!("/ {input}"),
            Style::default().fg(color),
        )];
        if self.in_search_mode && end == self.search_input.len() {
            if let Some(completion) = &self.completion {
                let mut visible = String::new();
                for c in completion.chars() {
                    let width = cell_width(&c);
                    if used_width + width > input_width {
                        break;
                    }
                    visible.push(c);
                    used_width += width;
                }
                spans.push(Span::styled(
                    visible,
                    Style::default().fg(theme.search_preview_color()),
                ));
            }
        }
        frame.render_widget(Paragraph::new(Line::from(spans)), area);
        if self.in_search_mode {
            // A highlighted cell, not the terminal's cursor: the stars redraw
            // many times a second, and the real cursor would jump to each one.
            let cursor_x = (2 + cursor_column as u16).min(area.width - 1);
            frame.buffer_mut().set_style(
                Rect::new(area.x + cursor_x, area.y, 1, 1),
                Style::default().fg(color).add_modifier(Modifier::REVERSED),
            );
        }
    }
    // Handles key events. Returns true if search must be exited
    pub fn handle_key(&mut self, event: &KeyEvent) -> SearchAction {
        if event.modifiers.contains(KeyModifiers::CONTROL) {
            return SearchAction::None;
        }
        match event.code {
            KeyCode::Char(c) => self.insert_char(c),
            KeyCode::Backspace => self.remove_previous(),
            KeyCode::Delete => self.remove_next(),
            KeyCode::Left => return self.cursor_left(),
            KeyCode::Right => return self.cursor_right(),
            KeyCode::Tab => return self.complete_search(),
            KeyCode::Esc => return self.exit_search(),
            KeyCode::Enter => return SearchAction::Exit,
            _ => return SearchAction::None,
        };
        self.update_completion();
        SearchAction::Update
    }

    fn exit_search(&mut self) -> SearchAction {
        self.input_position = 0;
        self.search_input.clear();
        self.completion = None;
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

#[cfg(test)]
mod tests {
    use super::*;
    use linutil_core::{ego_tree::Tree, Command, ListNode};
    use ratatui::{backend::TestBackend, crossterm::event::KeyModifiers, Terminal};
    use std::rc::Rc;

    fn node(name: &str, command: Command) -> Rc<ListNode> {
        Rc::new(ListNode {
            name: name.to_owned(),
            description: String::new(),
            command,
            task_list: String::new(),
            multi_select: true,
        })
    }

    fn tabs() -> Vec<Tab> {
        let mut first = Tree::new(node("root", Command::None));
        {
            let mut root = first.root_mut();
            let mut directory = root.append(node("Tools", Command::None));
            directory.append(node("Alpha Tool", Command::Raw("true".into())));
        }
        let mut second = Tree::new(node("root", Command::None));
        second
            .root_mut()
            .append(node("Beta Tool", Command::Raw("true".into())));
        vec![
            Tab {
                name: "First".into(),
                tree: first,
            },
            Tab {
                name: "Second".into(),
                tree: second,
            },
        ]
    }

    fn key(code: KeyCode) -> KeyEvent {
        KeyEvent::new(code, KeyModifiers::NONE)
    }

    #[test]
    fn search_keeps_global_leaf_matches_and_local_directory_browsing() {
        let tabs = tabs();
        let root = tabs[0].tree.root().id();
        let mut filter = Filter::new();
        filter.update_items(&tabs, 0, root);
        assert_eq!(filter.items.len(), 1);
        assert!(filter.items[0].has_children);
        for c in "tool".chars() {
            filter.handle_key(&key(KeyCode::Char(c)));
        }
        filter.update_items(&tabs, 0, root);
        assert_eq!(
            filter
                .items
                .iter()
                .map(|item| item.node.name.as_str())
                .collect::<Vec<_>>(),
            ["Alpha Tool", "Beta Tool"]
        );
        assert!(filter.items.iter().all(|item| !item.has_children));
        assert!(filter.is_filtered());
    }

    #[test]
    fn editing_completion_and_abort_preserve_search_behavior() {
        let tabs = tabs();
        let root = tabs[0].tree.root().id();
        let mut filter = Filter::new();
        filter.activate_search();
        for c in "Alphx".chars() {
            filter.handle_key(&key(KeyCode::Char(c)));
        }
        filter.handle_key(&key(KeyCode::Left));
        filter.handle_key(&key(KeyCode::Delete));
        filter.handle_key(&key(KeyCode::Char('a')));
        filter.update_items(&tabs, 0, root);
        assert_eq!(filter.completion.as_deref(), Some(" tool"));
        assert!(matches!(
            filter.handle_key(&key(KeyCode::Tab)),
            SearchAction::Update
        ));
        assert_eq!(filter.search_input.iter().collect::<String>(), "Alpha tool");
        assert!(matches!(
            filter.handle_key(&key(KeyCode::Enter)),
            SearchAction::Exit
        ));
        assert!(filter.is_filtered());
        assert!(matches!(
            filter.handle_key(&key(KeyCode::Esc)),
            SearchAction::Exit
        ));
        assert!(!filter.is_filtered());
        assert_eq!(filter.input_position, 0);
    }

    #[test]
    fn long_unicode_search_keeps_cursor_in_embedded_header() {
        let mut filter = Filter::new();
        filter.activate_search();
        for c in "long界🙂search界🙂".chars() {
            filter.handle_key(&key(KeyCode::Char(c)));
        }
        filter.completion = Some(" completion界🙂".into());
        let mut terminal = Terminal::new(TestBackend::new(30, 5)).unwrap();
        let area = Rect::new(3, 2, 12, 1);
        for position in [filter.search_input.len(), 5, 0] {
            filter.input_position = position;
            terminal
                .draw(|frame| filter.draw_searchbar(frame, area, &Theme::Compatible))
                .unwrap();
            let cursor = cursor_cell(&terminal);
            assert!(area.contains(cursor), "cursor {cursor:?} outside {area:?}");
            assert_eq!(terminal.backend().buffer()[(area.x, area.y)].symbol(), "/");
            assert_eq!(
                terminal.backend().buffer()[(area.right(), area.y)].symbol(),
                " "
            );
        }
        // Even an undersized header must not place the cursor outside its bounds.
        let tiny = Rect::new(3, 2, 1, 1);
        terminal
            .draw(|frame| filter.draw_searchbar(frame, tiny, &Theme::Compatible))
            .unwrap();
        assert!(tiny.contains(cursor_cell(&terminal)));
    }

    fn cursor_cell(terminal: &Terminal<TestBackend>) -> Position {
        let buffer = terminal.backend().buffer();
        let cells: Vec<Position> = buffer
            .area
            .positions()
            .filter(|&position| buffer[position].modifier.contains(Modifier::REVERSED))
            .collect();
        assert_eq!(cells.len(), 1, "one cursor cell");
        cells[0]
    }

    #[test]
    fn ctrl_c_in_search_mode_is_ignored() {
        let mut filter = Filter::new();
        filter.activate_search();
        let ctrl_c = KeyEvent::new(KeyCode::Char('c'), KeyModifiers::CONTROL);
        assert!(matches!(filter.handle_key(&ctrl_c), SearchAction::None));
        assert!(filter.search_input.is_empty());
    }
}

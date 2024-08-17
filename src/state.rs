use crate::{
    float::{Float, FloatContent},
    floating_text::FloatingText,
    running_command::{Command, RunningCommand},
    tabs::{ListNode, Tab},
    theme::Theme,
};
use crossterm::event::{KeyCode, KeyEvent, KeyEventKind};
use ego_tree::NodeId;
use ratatui::{
    layout::{Constraint, Direction, Layout},
    style::{Color, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListState, Paragraph},
    Frame,
};
use std::path::Path;

pub struct AppState {
    /// Selected theme
    theme: Theme,
    /// Currently focused area
    focus: Focus,
    /// List of tabs
    tabs: Vec<Tab>,
    /// Current tab
    current_tab: ListState,
    /// Current search query
    search_query: String,
    /// Current items
    items: Vec<ListEntry>,
    /// This stack keeps track of our "current dirrectory". You can think of it as `pwd`. but not
    /// just the current directory, all paths that took us here, so we can "cd .."
    visit_stack: Vec<NodeId>,
    /// This is the state asociated with the list widget, used to display the selection in the
    /// widget
    selection: ListState,
}

pub enum Focus {
    Search,
    TabList,
    List,
    FloatingWindow(Float),
}

struct ListEntry {
    node: ListNode,
    id: NodeId,
    has_children: bool,
}

impl AppState {
    pub fn new(theme: Theme, temp_path: &Path, override_validation: bool) -> Self {
        let tabs = crate::tabs::get_tabs(temp_path, !override_validation);
        let root_id = tabs[0].tree.root().id();
        let mut state = Self {
            theme,
            focus: Focus::List,
            tabs,
            current_tab: ListState::default().with_selected(Some(0)),
            search_query: String::new(),
            items: vec![],
            visit_stack: vec![root_id],
            selection: ListState::default().with_selected(Some(0)),
        };
        state.update_items();
        state
    }
    pub fn draw(&mut self, frame: &mut Frame) {
        let longest_tab_display_len = self
            .tabs
            .iter()
            .map(|tab| tab.name.len() + self.theme.tab_icon().len())
            .max()
            .unwrap_or(0);

        let horizontal = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([
                Constraint::Min(longest_tab_display_len as u16 + 5),
                Constraint::Percentage(100),
            ])
            .split(frame.size());
        let left_chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([Constraint::Length(3), Constraint::Min(1)])
            .split(horizontal[0]);

        let tabs = self
            .tabs
            .iter()
            .map(|tab| tab.name.as_str())
            .collect::<Vec<_>>();

        let tab_hl_style = if let Focus::TabList = self.focus {
            Style::default().reversed().fg(self.theme.tab_color())
        } else {
            Style::new().fg(self.theme.tab_color())
        };

        let list = List::new(tabs)
            .block(Block::default().borders(Borders::ALL))
            .highlight_style(tab_hl_style)
            .highlight_symbol(self.theme.tab_icon());
        frame.render_stateful_widget(list, left_chunks[1], &mut self.current_tab);

        let chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([Constraint::Length(3), Constraint::Min(1)].as_ref())
            .split(horizontal[1]);

        // Render search bar
        let search_text = match self.focus {
            Focus::Search => Span::raw(&self.search_query),
            _ if !self.search_query.is_empty() => Span::raw(&self.search_query),
            _ => Span::raw("Press / to search"),
        };
        let search_bar = Paragraph::new(search_text)
            .block(Block::default().borders(Borders::ALL))
            .style(Style::default().fg(if let Focus::Search = self.focus {
                Color::Blue
            } else {
                Color::DarkGray
            }));
        frame.render_widget(search_bar, chunks[0]);

        let mut items: Vec<Line> = Vec::new();
        if !self.at_root() {
            items.push(
                Line::from(format!("{}  ..", self.theme.dir_icon())).style(self.theme.dir_color()),
            );
        }

        items.extend(self.items.iter().map(
            |ListEntry {
                 node, has_children, ..
             }| {
                if *has_children {
                    Line::from(format!("{}  {}", self.theme.dir_icon(), node.name))
                        .style(self.theme.dir_color())
                } else {
                    Line::from(format!("{}  {}", self.theme.cmd_icon(), node.name))
                        .style(self.theme.cmd_color())
                }
            },
        ));

        // Create the list widget with items
        let list = List::new(items)
            .highlight_style(if let Focus::List = self.focus {
                Style::default().reversed()
            } else {
                Style::new()
            })
            .block(Block::default().borders(Borders::ALL).title(format!(
                "Linux Toolbox - {}",
                chrono::Local::now().format("%Y-%m-%d")
            )))
            .scroll_padding(1);
        frame.render_stateful_widget(list, chunks[1], &mut self.selection);

        if let Focus::FloatingWindow(float) = &mut self.focus {
            float.draw(frame, chunks[1]);
        }
    }
    pub fn handle_key(&mut self, key: &KeyEvent) -> bool {
        match &mut self.focus {
            Focus::FloatingWindow(command) => {
                if command.handle_key_event(key) {
                    self.focus = Focus::List;
                }
            }
            Focus::Search => {
                match key.code {
                    KeyCode::Char(c) => self.search_query.push(c),
                    KeyCode::Backspace => {
                        self.search_query.pop();
                    }
                    KeyCode::Esc => {
                        self.search_query = String::new();
                        self.exit_search();
                    }
                    KeyCode::Enter => self.exit_search(),
                    _ => return true,
                }
                self.update_items();
            }
            _ if key.code == KeyCode::Char('q') => return false,
            Focus::TabList => match key.code {
                KeyCode::Enter | KeyCode::Char('l') | KeyCode::Right | KeyCode::Tab => {
                    self.focus = Focus::List
                }
                KeyCode::Char('j') | KeyCode::Down
                    if self.current_tab.selected().unwrap() + 1 < self.tabs.len() =>
                {
                    self.current_tab.select_next();
                    self.refresh_tab();
                }
                KeyCode::Char('k') | KeyCode::Up => {
                    self.current_tab.select_previous();
                    self.refresh_tab();
                }
                KeyCode::Char('/') => self.enter_search(),
                KeyCode::Char('t') => self.theme = self.theme.next(),
                KeyCode::Char('T') => self.theme = self.theme.prev(),
                _ => {}
            },
            Focus::List if key.kind != KeyEventKind::Release => match key.code {
                KeyCode::Char('j') | KeyCode::Down => self.selection.select_next(),
                KeyCode::Char('k') | KeyCode::Up => self.selection.select_previous(),
                KeyCode::Char('p') => self.enable_preview(),
                KeyCode::Enter | KeyCode::Char('l') | KeyCode::Right => self.handle_enter(),
                KeyCode::Char('h') | KeyCode::Left => {
                    if self.at_root() {
                        self.focus = Focus::TabList;
                    } else {
                        self.enter_parent_directory();
                    }
                }
                KeyCode::Char('/') => self.enter_search(),
                KeyCode::Tab => self.focus = Focus::TabList,
                KeyCode::Char('t') => self.theme = self.theme.next(),
                KeyCode::Char('T') => self.theme = self.theme.prev(),
                _ => {}
            },
            _ => {}
        };
        true
    }
    pub fn update_items(&mut self) {
        if self.search_query.is_empty() {
            let curr = self.tabs[self.current_tab.selected().unwrap()]
                .tree
                .get(*self.visit_stack.last().unwrap())
                .unwrap();

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

            let query_lower = self.search_query.to_lowercase();
            for tab in self.tabs.iter() {
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
            self.items.sort_by(|a, b| a.node.name.cmp(&b.node.name));
        }
    }
    /// Checks ehther the current tree node is the root node (can we go up the tree or no)
    /// Returns `true` if we can't go up the tree (we are at the tree root)
    /// else returns `false`
    fn at_root(&self) -> bool {
        self.visit_stack.len() == 1
    }
    fn enter_parent_directory(&mut self) {
        self.visit_stack.pop();
        self.selection.select(Some(0));
        self.update_items();
    }
    fn get_selected_command(&mut self, change_directory: bool) -> Option<Command> {
        let mut selected_index = self.selection.selected().unwrap_or(0);

        if !self.at_root() && selected_index == 0 {
            if change_directory {
                self.enter_parent_directory();
            }
            return None;
        }
        if !self.at_root() {
            selected_index = selected_index.saturating_sub(1);
        }

        if let Some(item) = self.items.get(selected_index) {
            if !item.has_children {
                return Some(item.node.command.clone());
            } else if change_directory {
                self.visit_stack.push(item.id);
                self.selection.select(Some(0));
                self.update_items();
            }
        }
        None
    }
    fn enable_preview(&mut self) {
        if let Some(command) = self.get_selected_command(false) {
            if let Some(preview) = FloatingText::from_command(&command) {
                self.spawn_float(preview, 80, 80);
            }
        }
    }
    fn handle_enter(&mut self) {
        if let Some(cmd) = self.get_selected_command(true) {
            let command = RunningCommand::new(cmd);
            self.spawn_float(command, 80, 80);
        }
    }
    fn spawn_float<T: FloatContent + 'static>(&mut self, float: T, width: u16, height: u16) {
        self.focus = Focus::FloatingWindow(Float::new(Box::new(float), width, height));
    }
    fn enter_search(&mut self) {
        self.focus = Focus::Search;
        self.selection.select(None);
    }
    fn exit_search(&mut self) {
        self.selection.select(Some(0));
        self.focus = Focus::List;
        self.update_items();
    }
    fn refresh_tab(&mut self) {
        self.visit_stack = vec![self.tabs[self.current_tab.selected().unwrap()]
            .tree
            .root()
            .id()];
        self.selection.select(Some(0));
        self.update_items();
    }
}

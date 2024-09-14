use crate::{
    filter::{Filter, SearchAction},
    float::{Float, FloatContent},
    floating_text::FloatingText,
    hint::{draw_shortcuts, SHORTCUT_LINES},
    running_command::RunningCommand,
    theme::Theme,
};
use crossterm::event::{KeyCode, KeyEvent, KeyEventKind};
use ego_tree::NodeId;
use linutil_core::{Command, ListNode, Tab};
use ratatui::{
    layout::{Alignment, Constraint, Direction, Layout},
    style::{Style, Stylize},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListState, Paragraph},
    Frame,
};

pub struct AppState {
    /// Selected theme
    theme: Theme,
    /// Currently focused area
    pub focus: Focus,
    /// List of tabs
    tabs: Vec<Tab>,
    /// Current tab
    current_tab: ListState,
    /// This stack keeps track of our "current dirrectory". You can think of it as `pwd`. but not
    /// just the current directory, all paths that took us here, so we can "cd .."
    visit_stack: Vec<NodeId>,
    /// This is the state asociated with the list widget, used to display the selection in the
    /// widget
    selection: ListState,
    filter: Filter,
}

pub enum Focus {
    Search,
    TabList,
    List,
    FloatingWindow(Float),
}

pub struct ListEntry {
    pub node: ListNode,
    pub id: NodeId,
    pub has_children: bool,
}

impl AppState {
    pub fn new(theme: Theme, override_validation: bool) -> Self {
        let tabs = linutil_core::get_tabs(!override_validation);
        let root_id = tabs[0].tree.root().id();
        let mut state = Self {
            theme,
            focus: Focus::List,
            tabs,
            current_tab: ListState::default().with_selected(Some(0)),
            visit_stack: vec![root_id],
            selection: ListState::default().with_selected(Some(0)),
            filter: Filter::new(),
        };
        state.update_items();
        state
    }
    pub fn draw(&mut self, frame: &mut Frame) {
        let label_block =
            Block::default()
                .borders(Borders::all())
                .border_set(ratatui::symbols::border::Set {
                    top_left: " ",
                    top_right: " ",
                    bottom_left: " ",
                    bottom_right: " ",
                    vertical_left: " ",
                    vertical_right: " ",
                    horizontal_top: "*",
                    horizontal_bottom: "*",
                });
        let str1 = "Linutil ";
        let str2 = "by Chris Titus";
        let label = Paragraph::new(Line::from(vec![
            Span::styled(str1, Style::default().bold()),
            Span::styled(str2, Style::default().italic()),
        ]))
        .block(label_block)
        .alignment(Alignment::Center);

        let longest_tab_display_len = self
            .tabs
            .iter()
            .map(|tab| tab.name.len() + self.theme.tab_icon().len())
            .max()
            .unwrap_or(0)
            .max(str1.len() + str2.len());

        let vertical = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Percentage(100),
                Constraint::Min(2 + SHORTCUT_LINES as u16),
            ])
            .margin(0)
            .split(frame.area());

        let horizontal = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([
                Constraint::Min(longest_tab_display_len as u16 + 5),
                Constraint::Percentage(100),
            ])
            .split(vertical[0]);

        let left_chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([Constraint::Length(3), Constraint::Min(1)])
            .split(horizontal[0]);
        frame.render_widget(label, left_chunks[0]);

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

        self.filter.draw_searchbar(frame, chunks[0], &self.theme);

        let mut items: Vec<Line> = Vec::new();
        if !self.at_root() {
            items.push(
                Line::from(format!("{}  ..", self.theme.dir_icon())).style(self.theme.dir_color()),
            );
        }

        items.extend(self.filter.item_list().iter().map(
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
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title(format!("Linux Toolbox - {}", env!("BUILD_DATE"))),
            )
            .scroll_padding(1);
        frame.render_stateful_widget(list, chunks[1], &mut self.selection);

        if let Focus::FloatingWindow(float) = &mut self.focus {
            float.draw(frame, chunks[1]);
        }

        draw_shortcuts(self, frame, vertical[1]);
    }
    pub fn handle_key(&mut self, key: &KeyEvent) -> bool {
        match &mut self.focus {
            Focus::FloatingWindow(command) => {
                if command.handle_key_event(key) {
                    self.focus = Focus::List;
                }
            }
            Focus::Search => match self.filter.handle_key(key) {
                SearchAction::Exit => self.exit_search(),
                SearchAction::Update => self.update_items(),
                _ => {}
            },
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
                KeyCode::Char('t') => self.theme.next(),
                KeyCode::Char('T') => self.theme.prev(),
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
                KeyCode::Char('t') => self.theme.next(),
                KeyCode::Char('T') => self.theme.prev(),
                _ => {}
            },
            _ => {}
        };
        true
    }
    fn update_items(&mut self) {
        self.filter.update_items(
            &self.tabs,
            self.current_tab.selected().unwrap(),
            *self.visit_stack.last().unwrap(),
        );
    }
    /// Checks ehther the current tree node is the root node (can we go up the tree or no)
    /// Returns `true` if we can't go up the tree (we are at the tree root)
    /// else returns `false`
    pub fn at_root(&self) -> bool {
        self.visit_stack.len() == 1
    }
    fn enter_parent_directory(&mut self) {
        self.visit_stack.pop();
        self.selection.select(Some(0));
        self.update_items();
    }
    pub fn get_selected_command(&self) -> Option<Command> {
        let mut selected_index = self.selection.selected().unwrap_or(0);

        if !self.at_root() && selected_index == 0 {
            return None;
        }
        if !self.at_root() {
            selected_index = selected_index.saturating_sub(1);
        }

        if let Some(item) = self.filter.item_list().get(selected_index) {
            if !item.has_children {
                return Some(item.node.command.clone());
            }
        }
        None
    }
    pub fn go_to_selected_dir(&mut self) {
        let mut selected_index = self.selection.selected().unwrap_or(0);

        if !self.at_root() && selected_index == 0 {
            self.enter_parent_directory();
            return;
        }

        if !self.at_root() {
            selected_index = selected_index.saturating_sub(1);
        }

        if let Some(item) = self.filter.item_list().get(selected_index) {
            if item.has_children {
                self.visit_stack.push(item.id);
                self.selection.select(Some(0));
                self.update_items();
            }
        }
    }
    pub fn selected_item_is_dir(&self) -> bool {
        let mut selected_index = self.selection.selected().unwrap_or(0);

        if !self.at_root() && selected_index == 0 {
            return false;
        }

        if !self.at_root() {
            selected_index = selected_index.saturating_sub(1);
        }

        if let Some(item) = self.filter.item_list().get(selected_index) {
            item.has_children
        } else {
            false
        }
    }

    pub fn selected_item_is_cmd(&self) -> bool {
        let mut selected_index = self.selection.selected().unwrap_or(0);

        if !self.at_root() && selected_index == 0 {
            return false;
        }

        if !self.at_root() {
            selected_index = selected_index.saturating_sub(1);
        }

        if let Some(item) = self.filter.item_list().get(selected_index) {
            !item.has_children
        } else {
            false
        }
    }
    pub fn selected_item_is_up_dir(&self) -> bool {
        let selected_index = self.selection.selected().unwrap_or(0);

        !self.at_root() && selected_index == 0
    }
    fn enable_preview(&mut self) {
        if let Some(command) = self.get_selected_command() {
            if let Some(preview) = FloatingText::from_command(&command) {
                self.spawn_float(preview, 80, 80);
            }
        }
    }
    fn handle_enter(&mut self) {
        if let Some(cmd) = self.get_selected_command() {
            let command = RunningCommand::new(cmd);
            self.spawn_float(command, 80, 80);
        } else {
            self.go_to_selected_dir();
        }
    }
    fn spawn_float<T: FloatContent + 'static>(&mut self, float: T, width: u16, height: u16) {
        self.focus = Focus::FloatingWindow(Float::new(Box::new(float), width, height));
    }
    fn enter_search(&mut self) {
        self.focus = Focus::Search;
        self.filter.activate_search();
        self.selection.select(None);
    }
    fn exit_search(&mut self) {
        self.selection.select(Some(0));
        self.focus = Focus::List;
        self.filter.deactivate_search();
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

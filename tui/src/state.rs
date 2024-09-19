use crate::{
    filter::{Filter, SearchAction},
    float::{Float, FloatContent},
    floating_text::{FloatingText, FloatingTextMode},
    hint::{draw_shortcuts, SHORTCUT_LINES},
    running_command::RunningCommand,
    theme::Theme,
};
use crossterm::event::{KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use ego_tree::NodeId;
use linutil_core::{Command, ListNode, Tab};
use ratatui::{
    layout::{Alignment, Constraint, Direction, Layout},
    style::{Style, Stylize},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListState, Paragraph},
    Frame,
};

const MIN_WIDTH: u16 = 77;
const MIN_HEIGHT: u16 = 19;

pub struct AppState {
    /// Selected theme
    theme: Theme,
    /// Currently focused area
    pub focus: Focus,
    /// List of tabs
    tabs: Vec<Tab>,
    /// Current tab
    current_tab: ListState,
    /// This stack keeps track of our "current directory". You can think of it as `pwd`. but not
    /// just the current directory, all paths that took us here, so we can "cd .."
    visit_stack: Vec<NodeId>,
    /// This is the state asociated with the list widget, used to display the selection in the
    /// widget
    selection: ListState,
    filter: Filter,
    multi_select: bool,
    selected_commands: Vec<Command>,
    drawable: bool,
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
            multi_select: false,
            selected_commands: Vec::new(),
            drawable: false,
        };
        state.update_items();
        state
    }
    pub fn draw(&mut self, frame: &mut Frame) {
        let terminal_size = frame.area();

        if terminal_size.width < MIN_WIDTH || terminal_size.height < MIN_HEIGHT {
            let size_warning_message = format!(
                "Terminal size too small:\nWidth = {} Height = {}\n\nMinimum size:\nWidth = {}  Height = {}",
                terminal_size.width,
                terminal_size.height,
                MIN_WIDTH,
                MIN_HEIGHT,
            );

            let warning_paragraph = Paragraph::new(size_warning_message.clone())
                .alignment(Alignment::Center)
                .style(Style::default().fg(ratatui::style::Color::Red).bold())
                .wrap(ratatui::widgets::Wrap { trim: true });

            // Get the maximum width and height of text lines
            let text_lines: Vec<String> = size_warning_message
                .lines()
                .map(|line| line.to_string())
                .collect();
            let max_line_length = text_lines.iter().map(|line| line.len()).max().unwrap_or(0);
            let num_lines = text_lines.len();

            // Calculate the centered area
            let centered_area = ratatui::layout::Rect {
                x: terminal_size.x + (terminal_size.width - max_line_length as u16) / 2,
                y: terminal_size.y + (terminal_size.height - num_lines as u16) / 2,
                width: max_line_length as u16,
                height: num_lines as u16,
            };
            frame.render_widget(warning_paragraph, centered_area);
            self.drawable = false;
        } else {
            self.drawable = true;
        }

        if !self.drawable {
            return;
        }

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
                let is_selected = self.selected_commands.contains(&node.command);
                let (indicator, style) = if is_selected {
                    (self.theme.multi_select_icon(), Style::default().bold())
                } else {
                    ("", Style::new())
                };
                if *has_children {
                    Line::from(format!(
                        "{}  {} {}",
                        self.theme.dir_icon(),
                        node.name,
                        indicator
                    ))
                    .style(self.theme.dir_color())
                } else {
                    Line::from(format!(
                        "{}  {} {}",
                        self.theme.cmd_icon(),
                        node.name,
                        indicator
                    ))
                    .style(self.theme.cmd_color())
                    .patch_style(style)
                }
            },
        ));

        let style = if let Focus::List = self.focus {
            Style::default().reversed()
        } else {
            Style::new()
        };

        let title = format!(
            "Linux Toolbox - {} {}",
            env!("BUILD_DATE"),
            self.multi_select.then(|| "[Multi-Select]").unwrap_or("")
        );

        // Create the list widget with items
        let list = List::new(items)
            .highlight_style(style)
            .block(Block::default().borders(Borders::ALL).title(title))
            .scroll_padding(1);
        frame.render_stateful_widget(list, chunks[1], &mut self.selection);

        if let Focus::FloatingWindow(float) = &mut self.focus {
            float.draw(frame, chunks[1]);
        }

        draw_shortcuts(self, frame, vertical[1]);
    }

    pub fn handle_key(&mut self, key: &KeyEvent) -> bool {
        // This should be defined first to allow closing
        // the application even when not drawable ( If terminal is small )
        // Exit on 'q' or 'Ctrl-c' input
        if matches!(self.focus, Focus::TabList | Focus::List)
            && (key.code == KeyCode::Char('q')
                || key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('c'))
        {
            return false;
        }

        // If UI is not drawable returning true will mark as the key handled
        if !self.drawable {
            return true;
        }

        // Handle key only when Tablist or List is focused
        // Prevents exiting the application even when a command is running
        // Add keys here which should work on both TabList and List
        if matches!(self.focus, Focus::TabList | Focus::List) {
            match key.code {
                KeyCode::Tab => {
                    if self.current_tab.selected().unwrap() == self.tabs.len() - 1 {
                        self.current_tab.select_first();
                    } else {
                        self.current_tab.select_next();
                    }
                    self.refresh_tab();
                }
                KeyCode::BackTab => {
                    if self.current_tab.selected().unwrap() == 0 {
                        self.current_tab.select(Some(self.tabs.len() - 1));
                    } else {
                        self.current_tab.select_previous();
                    }
                    self.refresh_tab();
                }
                _ => {}
            }
        }

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
            Focus::TabList => match key.code {
                KeyCode::Enter | KeyCode::Char('l') | KeyCode::Right => self.focus = Focus::List,

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
                KeyCode::Char('p') | KeyCode::Char('P') => self.enable_preview(),
                KeyCode::Char('d') | KeyCode::Char('D') => self.enable_description(),
                KeyCode::Enter | KeyCode::Char('l') | KeyCode::Right => self.handle_enter(),
                KeyCode::Char('h') | KeyCode::Left => {
                    if self.at_root() {
                        self.focus = Focus::TabList;
                    } else {
                        self.enter_parent_directory();
                    }
                }
                KeyCode::Char('/') => self.enter_search(),
                KeyCode::Char('t') => self.theme.next(),
                KeyCode::Char('T') => self.theme.prev(),
                KeyCode::Char('v') | KeyCode::Char('V') => self.toggle_multi_select(),
                KeyCode::Char(' ') if self.multi_select => self.toggle_selection(),
                _ => {}
            },
            _ => (),
        };
        true
    }
    fn toggle_multi_select(&mut self) {
        if self.is_current_tab_multi_selectable() {
            self.multi_select = !self.multi_select;
            if !self.multi_select {
                self.selected_commands.clear();
            }
        }
    }
    fn toggle_selection(&mut self) {
        if let Some(command) = self.get_selected_command() {
            if self.selected_commands.contains(&command) {
                self.selected_commands.retain(|c| c != &command);
            } else {
                self.selected_commands.push(command);
            }
        }
    }
    pub fn is_current_tab_multi_selectable(&self) -> bool {
        let index = self.current_tab.selected().unwrap_or(0);
        self.tabs
            .get(index)
            .map_or(false, |tab| tab.multi_selectable)
    }
    fn update_items(&mut self) {
        self.filter.update_items(
            &self.tabs,
            self.current_tab.selected().unwrap(),
            *self.visit_stack.last().unwrap(),
        );
        if !self.is_current_tab_multi_selectable() {
            self.multi_select = false;
            self.selected_commands.clear();
        }
    }

    /// Checks either the current tree node is the root node (can we go up the tree or no)
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
    fn get_selected_node(&self) -> Option<&ListNode> {
        let mut selected_index = self.selection.selected().unwrap_or(0);

        if !self.at_root() && selected_index == 0 {
            return None;
        }
        if !self.at_root() {
            selected_index = selected_index.saturating_sub(1);
        }

        if let Some(item) = self.filter.item_list().get(selected_index) {
            if !item.has_children {
                return Some(&item.node);
            }
        }
        None
    }
    pub fn get_selected_command(&self) -> Option<Command> {
        self.get_selected_node().map(|node| node.command.clone())
    }
    fn get_selected_description(&self) -> Option<String> {
        self.get_selected_node()
            .map(|node| node.description.clone())
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

        self.filter
            .item_list()
            .get(selected_index)
            .map_or(false, |item| item.has_children)
    }

    pub fn selected_item_is_cmd(&self) -> bool {
        !self.selected_item_is_dir()
    }
    pub fn selected_item_is_up_dir(&self) -> bool {
        let selected_index = self.selection.selected().unwrap_or(0);

        !self.at_root() && selected_index == 0
    }
    fn enable_preview(&mut self) {
        if let Some(command) = self.get_selected_command() {
            if let Some(preview) = FloatingText::from_command(&command, FloatingTextMode::Preview) {
                self.spawn_float(preview, 80, 80);
            }
        }
    }
    fn enable_description(&mut self) {
        if let Some(command_description) = self.get_selected_description() {
            let description_content: Vec<String> = vec![]
                .into_iter()
                .chain(command_description.lines().map(|line| line.to_string())) // New line when \n is given in toml
                .collect();

            let description = FloatingText::new(description_content, FloatingTextMode::Description);
            self.spawn_float(description, 80, 80);
        }
    }

    fn handle_enter(&mut self) {
        if self.selected_item_is_cmd() {
            if self.selected_commands.is_empty() {
                if let Some(cmd) = self.get_selected_command() {
                    self.selected_commands.push(cmd);
                }
            }
            let command = RunningCommand::new(self.selected_commands.clone());
            self.spawn_float(command, 80, 80);
            self.selected_commands.clear();
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

use crate::{
    confirmation::{ConfirmPrompt, ConfirmStatus},
    filter::{Filter, SearchAction},
    float::{Float, FloatContent},
    floating_text::FloatingText,
    hint::{create_shortcut_list, Shortcut},
    running_command::RunningCommand,
    theme::Theme,
};

use linutil_core::{ego_tree::NodeId, Config, ListNode, TabList};
#[cfg(feature = "tips")]
use rand::Rng;
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, KeyEventKind, KeyModifiers},
    layout::{Alignment, Constraint, Direction, Flex, Layout},
    style::{Style, Stylize},
    text::{Line, Span, Text},
    widgets::{Block, Borders, List, ListState, Paragraph},
    Frame,
};
use std::path::PathBuf;
use std::rc::Rc;

const MIN_WIDTH: u16 = 100;
const MIN_HEIGHT: u16 = 25;
const TITLE: &str = concat!(" Linux Toolbox - ", env!("CARGO_PKG_VERSION"), " ");
const ACTIONS_GUIDE: &str = "List of important tasks performed by commands' names:

D  - disk modifications (ex. partitioning) (privileged)
FI - flatpak installation
FM - file modification
I  - installation (privileged)
K  - kernel modifications (privileged)
MP - package manager actions
SI - full system installation
SS - systemd actions (privileged)
RP - package removal

P* - privileged *
";

pub struct AppState {
    /// Selected theme
    theme: Theme,
    /// Currently focused area
    pub focus: Focus,
    /// List of tabs
    tabs: TabList,
    /// Current tab
    current_tab: ListState,
    /// This stack keeps track of our "current directory". You can think of it as `pwd`. but not
    /// just the current directory, all paths that took us here, so we can "cd .."
    visit_stack: Vec<(NodeId, usize)>,
    /// This is the state associated with the list widget, used to display the selection in the
    /// widget
    selection: ListState,
    filter: Filter,
    multi_select: bool,
    selected_commands: Vec<Rc<ListNode>>,
    drawable: bool,
    #[cfg(feature = "tips")]
    tip: String,
    size_bypass: bool,
    skip_confirmation: bool,
}

pub enum Focus {
    Search,
    TabList,
    List,
    FloatingWindow(Float<dyn FloatContent>),
    ConfirmationPrompt(Float<ConfirmPrompt>),
}

pub struct ListEntry {
    pub node: Rc<ListNode>,
    pub id: NodeId,
    pub has_children: bool,
}

enum SelectedItem {
    UpDir,
    Directory,
    Command,
    None,
}

impl AppState {
    pub fn new(
        config_path: Option<PathBuf>,
        theme: Theme,
        override_validation: bool,
        size_bypass: bool,
        skip_confirmation: bool,
    ) -> Self {
        let tabs = linutil_core::get_tabs(!override_validation);
        let root_id = tabs[0].tree.root().id();

        let auto_execute_commands = config_path.map(|path| Config::from_file(&path).auto_execute);

        let mut state = Self {
            theme,
            focus: Focus::List,
            tabs,
            current_tab: ListState::default().with_selected(Some(0)),
            visit_stack: vec![(root_id, 0usize)],
            selection: ListState::default().with_selected(Some(0)),
            filter: Filter::new(),
            multi_select: false,
            selected_commands: Vec::new(),
            drawable: false,
            #[cfg(feature = "tips")]
            tip: get_random_tip(),
            size_bypass,
            skip_confirmation,
        };

        state.update_items();
        if let Some(auto_execute_commands) = auto_execute_commands {
            state.handle_initial_auto_execute(&auto_execute_commands);
        }

        state
    }

    fn handle_initial_auto_execute(&mut self, auto_execute_commands: &[String]) {
        self.selected_commands = auto_execute_commands
            .iter()
            .filter_map(|name| self.tabs.iter().find_map(|tab| tab.find_command(name)))
            .collect();

        if !self.selected_commands.is_empty() {
            let cmd_names: Vec<_> = self
                .selected_commands
                .iter()
                .map(|node| node.name.as_str())
                .collect();

            let prompt = ConfirmPrompt::new(&cmd_names);
            self.focus = Focus::ConfirmationPrompt(Float::new(Box::new(prompt), 40, 40));
        }
    }

    fn get_list_item_shortcut(&self) -> Box<[Shortcut]> {
        if self.selected_item_is_dir() {
            Box::new([Shortcut::new("Go to selected dir", ["l", "Right", "Enter"])])
        } else {
            Box::new([
                Shortcut::new("Run selected command", ["l", "Right", "Enter"]),
                Shortcut::new("Enable preview", ["p"]),
                Shortcut::new("Command Description", ["d"]),
            ])
        }
    }

    pub fn get_keybinds(&self) -> (&str, Box<[Shortcut]>) {
        match self.focus {
            Focus::Search => (
                "Search bar",
                Box::new([
                    Shortcut::new("Abort search", ["Esc", "CTRL-c"]),
                    Shortcut::new("Search", ["Enter"]),
                ]),
            ),

            Focus::List => {
                let mut hints = Vec::new();
                hints.push(Shortcut::new("Exit linutil", ["q", "CTRL-c"]));

                if self.at_root() {
                    hints.push(Shortcut::new("Focus tab list", ["h", "Left"]));
                    hints.extend(self.get_list_item_shortcut());
                } else if self.selected_item_is_up_dir() {
                    hints.push(Shortcut::new(
                        "Go to parent directory",
                        ["l", "Right", "Enter", "h", "Left"],
                    ));
                } else {
                    hints.push(Shortcut::new("Go to parent directory", ["h", "Left"]));
                    hints.extend(self.get_list_item_shortcut());
                }

                hints.push(Shortcut::new("Select item above", ["k", "Up"]));
                hints.push(Shortcut::new("Select item below", ["j", "Down"]));
                hints.push(Shortcut::new("Next theme", ["t"]));
                hints.push(Shortcut::new("Previous theme", ["T"]));
                hints.push(Shortcut::new("Multi-selection mode", ["v"]));
                if self.multi_select {
                    hints.push(Shortcut::new("Select multiple commands", ["Space"]));
                }
                hints.push(Shortcut::new("Next tab", ["Tab"]));
                hints.push(Shortcut::new("Previous tab", ["Shift-Tab"]));
                hints.push(Shortcut::new("Important actions guide", ["g"]));

                ("Command list", hints.into_boxed_slice())
            }

            Focus::TabList => (
                "Tab list",
                Box::new([
                    Shortcut::new("Exit linutil", ["q", "CTRL-c"]),
                    Shortcut::new("Focus action list", ["l", "Right", "Enter"]),
                    Shortcut::new("Select item above", ["k", "Up"]),
                    Shortcut::new("Select item below", ["j", "Down"]),
                    Shortcut::new("Next theme", ["t"]),
                    Shortcut::new("Previous theme", ["T"]),
                    Shortcut::new("Next tab", ["Tab"]),
                    Shortcut::new("Previous tab", ["Shift-Tab"]),
                ]),
            ),

            Focus::FloatingWindow(ref float) => float.get_shortcut_list(),
            Focus::ConfirmationPrompt(ref prompt) => prompt.get_shortcut_list(),
        }
    }

    pub fn draw(&mut self, frame: &mut Frame) {
        let terminal_size = frame.area();

        if !self.size_bypass
            && (terminal_size.height < MIN_HEIGHT || terminal_size.width < MIN_WIDTH)
        {
            let warning = Paragraph::new(format!(
                "Terminal size too small:\nWidth = {} Height = {}\n\nMinimum size:\nWidth = {}  Height = {}",
                terminal_size.width,
                terminal_size.height,
                MIN_WIDTH,
                MIN_HEIGHT,
            ))
                .alignment(Alignment::Center)
                .style(Style::default().fg(ratatui::style::Color::Red).bold())
                .wrap(ratatui::widgets::Wrap { trim: true });

            let centered_layout = Layout::default()
                .direction(Direction::Vertical)
                .constraints([
                    Constraint::Fill(1),
                    Constraint::Length(5),
                    Constraint::Fill(1),
                ])
                .split(terminal_size);

            self.drawable = false;
            return frame.render_widget(warning, centered_layout[1]);
        } else {
            self.drawable = true;
        }

        let label_block = Block::default()
            .borders(Borders::ALL)
            .border_set(ratatui::symbols::border::ROUNDED)
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

        let (keybind_scope, shortcuts) = self.get_keybinds();

        let keybind_render_width = terminal_size.width - 2;

        let keybinds_block = Block::default()
            .title(format!(" {} ", keybind_scope))
            .borders(Borders::ALL)
            .border_set(ratatui::symbols::border::ROUNDED);

        let keybinds = create_shortcut_list(shortcuts, keybind_render_width);
        let n_lines = keybinds.len() as u16;

        let keybind_para = Paragraph::new(Text::from_iter(keybinds)).block(keybinds_block);

        let vertical = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Percentage(0),
                Constraint::Max(n_lines as u16 + 2),
            ])
            .flex(Flex::Legacy)
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
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_set(ratatui::symbols::border::ROUNDED),
            )
            .highlight_style(tab_hl_style)
            .highlight_symbol(self.theme.tab_icon());
        frame.render_stateful_widget(list, left_chunks[1], &mut self.current_tab);

        let chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([Constraint::Length(3), Constraint::Min(1)].as_ref())
            .split(horizontal[1]);

        let list_chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Percentage(70), Constraint::Percentage(30)].as_ref())
            .split(chunks[1]);

        self.filter.draw_searchbar(frame, chunks[0], &self.theme);

        let mut items: Vec<Line> = Vec::new();
        let mut task_items: Vec<Line> = Vec::new();

        if !self.at_root() {
            items.push(
                Line::from(format!("{}  ..", self.theme.dir_icon())).style(self.theme.dir_color()),
            );
            task_items.push(Line::from(" ").style(self.theme.dir_color()));
        }

        items.extend(self.filter.item_list().iter().map(
            |ListEntry {
                 node, has_children, ..
             }| {
                let is_selected = self.selected_commands.contains(node);
                let (indicator, style) = if is_selected {
                    (self.theme.multi_select_icon(), Style::default().bold())
                } else {
                    let ms_style = if self.multi_select && !node.multi_select {
                        Style::default().fg(self.theme.multi_select_disabled_color())
                    } else {
                        Style::new()
                    };
                    ("", ms_style)
                };
                if *has_children {
                    Line::from(format!(
                        "{}  {} {}",
                        self.theme.dir_icon(),
                        node.name,
                        indicator
                    ))
                    .style(self.theme.dir_color())
                    .patch_style(style)
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

        task_items.extend(self.filter.item_list().iter().map(
            |ListEntry {
                 node, has_children, ..
             }| {
                let ms_style = if self.multi_select && !node.multi_select {
                    Style::default().fg(self.theme.multi_select_disabled_color())
                } else {
                    Style::new()
                };
                if *has_children {
                    Line::from(" ")
                        .style(self.theme.dir_color())
                        .patch_style(ms_style)
                } else {
                    Line::from(format!("{} ", node.task_list))
                        .alignment(Alignment::Right)
                        .style(self.theme.cmd_color())
                        .bold()
                        .patch_style(ms_style)
                }
            },
        ));

        let style = if let Focus::List = self.focus {
            Style::default().reversed()
        } else {
            Style::new()
        };

        let title = if self.multi_select {
            &format!("{}[Multi-Select] ", TITLE)
        } else {
            TITLE
        };

        #[cfg(feature = "tips")]
        let bottom_title = Line::from(self.tip.as_str().bold().blue()).right_aligned();
        #[cfg(not(feature = "tips"))]
        let bottom_title = "";

        let task_list_title = Line::from(" Important Actions ").right_aligned();

        // Create the list widget with items
        let list = List::new(items)
            .highlight_style(style)
            .block(
                Block::default()
                    .borders(Borders::ALL & !Borders::RIGHT)
                    .border_set(ratatui::symbols::border::ROUNDED)
                    .title(title)
                    .title_bottom(bottom_title),
            )
            .scroll_padding(1);
        frame.render_stateful_widget(list, list_chunks[0], &mut self.selection);

        let disclaimer_list = List::new(task_items).highlight_style(style).block(
            Block::default()
                .borders(Borders::ALL & !Borders::LEFT)
                .border_set(ratatui::symbols::border::ROUNDED)
                .title(task_list_title),
        );

        frame.render_stateful_widget(disclaimer_list, list_chunks[1], &mut self.selection);

        match &mut self.focus {
            Focus::FloatingWindow(float) => float.draw(frame, chunks[1]),
            Focus::ConfirmationPrompt(prompt) => prompt.draw(frame, chunks[1]),
            _ => {}
        }

        frame.render_widget(keybind_para, vertical[1]);
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

        if matches!(self.focus, Focus::ConfirmationPrompt(_))
            && (key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('c'))
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

            Focus::ConfirmationPrompt(confirm) => {
                confirm.content.handle_key_event(key);
                match confirm.content.status {
                    ConfirmStatus::Abort => {
                        self.focus = Focus::List;
                        // selected command was pushed to selection list if multi-select was
                        // enabled, need to clear it to prevent state corruption
                        if !self.multi_select {
                            self.selected_commands.clear()
                        } else {
                            // Prevents non multi_selectable cmd from being pushed into the selected list
                            if let Some(node) = self.get_selected_node() {
                                if !node.multi_select {
                                    self.selected_commands.retain(|cmd| cmd.name != node.name);
                                }
                            }
                        }
                    }
                    ConfirmStatus::Confirm => self.handle_confirm_command(),
                    ConfirmStatus::None => {}
                }
            }

            Focus::Search => match self.filter.handle_key(key) {
                SearchAction::Exit => self.exit_search(),
                SearchAction::Update => self.update_items(),
                SearchAction::None => {}
            },

            Focus::TabList => match key.code {
                KeyCode::Enter | KeyCode::Char('l') | KeyCode::Right => self.focus = Focus::List,

                KeyCode::Char('j') | KeyCode::Down => self.scroll_tab_down(),

                KeyCode::Char('k') | KeyCode::Up => self.scroll_tab_up(),

                KeyCode::Char('/') => self.enter_search(),
                KeyCode::Char('t') => self.theme.next(),
                KeyCode::Char('T') => self.theme.prev(),
                KeyCode::Char('g') => self.toggle_task_list_guide(),
                _ => {}
            },

            Focus::List if key.kind != KeyEventKind::Release => match key.code {
                KeyCode::Char('j') | KeyCode::Down => self.scroll_down(),
                KeyCode::Char('k') | KeyCode::Up => self.scroll_up(),
                KeyCode::Char('p') | KeyCode::Char('P') => self.enable_preview(),
                KeyCode::Char('d') | KeyCode::Char('D') => self.enable_description(),
                KeyCode::Enter | KeyCode::Char('l') | KeyCode::Right => self.handle_enter(),
                KeyCode::Char('h') | KeyCode::Left => self.go_back(),
                KeyCode::Char('/') => self.enter_search(),
                KeyCode::Char('t') => self.theme.next(),
                KeyCode::Char('T') => self.theme.prev(),
                KeyCode::Char('g') => self.toggle_task_list_guide(),
                KeyCode::Char('v') | KeyCode::Char('V') => self.toggle_multi_select(),
                KeyCode::Char(' ') if self.multi_select => self.toggle_selection(),
                _ => {}
            },

            _ => (),
        };
        true
    }

    fn scroll_down(&mut self) {
        let len = self.filter.item_list().len();
        if len == 0 {
            return;
        }
        let current = self.selection.selected().unwrap_or(0);
        let max_index = if self.at_root() { len - 1 } else { len };
        let next = if current + 1 > max_index {
            0
        } else {
            current + 1
        };

        self.selection.select(Some(next));
    }

    fn scroll_up(&mut self) {
        let len = self.filter.item_list().len();
        if len == 0 {
            return;
        }
        let current = self.selection.selected().unwrap_or(0);
        let max_index = if self.at_root() { len - 1 } else { len };
        let next = if current == 0 { max_index } else { current - 1 };

        self.selection.select(Some(next));
    }

    fn toggle_multi_select(&mut self) {
        self.multi_select = !self.multi_select;
        if !self.multi_select {
            self.selected_commands.clear();
        }
    }

    fn toggle_selection(&mut self) {
        if let Some(node) = self.get_selected_node() {
            if node.multi_select {
                if self.selected_commands.contains(&node) {
                    self.selected_commands.retain(|c| c != &node);
                } else {
                    self.selected_commands.push(node);
                }
            }
        }
    }

    fn update_items(&mut self) {
        self.filter.update_items(
            &self.tabs,
            self.current_tab.selected().unwrap(),
            self.visit_stack.last().unwrap().0,
        );

        let len = self.filter.item_list().len();
        if len > 0 {
            let current = self.selection.selected().unwrap_or(0);
            self.selection.select(Some(current.min(len - 1)));
        } else {
            self.selection.select(None);
        }
    }

    /// Checks either the current tree node is the root node (can we go up the tree or no)
    /// Returns `true` if we can't go up the tree (we are at the tree root)
    /// else returns `false`
    pub fn at_root(&self) -> bool {
        self.visit_stack.len() == 1
    }

    fn go_back(&mut self) {
        if self.at_root() {
            self.focus = Focus::TabList;
        } else {
            self.enter_parent_directory();
        }
    }

    fn enter_parent_directory(&mut self) {
        if let Some((_, previous_position)) = self.visit_stack.pop() {
            self.selection.select(Some(previous_position));
            self.update_items();
        }
    }

    fn get_selected_node(&self) -> Option<Rc<ListNode>> {
        let mut selected_index = self.selection.selected().unwrap_or(0);

        if !self.at_root() && selected_index == 0 {
            return None;
        }
        if !self.at_root() {
            selected_index = selected_index.saturating_sub(1);
        }

        if let Some(item) = self.filter.item_list().get(selected_index) {
            if !item.has_children {
                return Some(item.node.clone());
            }
        }
        None
    }

    fn get_selected_description(&self) -> Option<String> {
        self.get_selected_node()
            .map(|node| node.description.clone())
    }

    pub fn go_to_selected_dir(&mut self) {
        let selected_index = self.selection.selected().unwrap_or(0);

        if !self.at_root() && selected_index == 0 {
            self.enter_parent_directory();
            return;
        }

        let actual_index = if self.at_root() {
            selected_index
        } else {
            selected_index - 1
        };

        if let Some(item) = self.filter.item_list().get(actual_index) {
            if item.has_children {
                self.visit_stack.push((item.id, selected_index));
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
        // Any item that is not a directory or up directory (..) must be a command
        self.selection.selected().is_some()
            && !(self.selected_item_is_up_dir() || self.selected_item_is_dir())
    }

    pub fn selected_item_is_up_dir(&self) -> bool {
        let selected_index = self.selection.selected().unwrap_or(0);
        !self.at_root() && selected_index == 0
    }

    fn enable_preview(&mut self) {
        if let Some(list_node) = self.get_selected_node() {
            let mut preview_title = "[Preview] - ".to_string();
            preview_title.push_str(list_node.name.as_str());
            if let Some(preview) = FloatingText::from_command(&list_node.command, preview_title) {
                self.spawn_float(preview, 80, 80);
            }
        }
    }

    fn enable_description(&mut self) {
        if let Some(command_description) = self.get_selected_description() {
            if !command_description.is_empty() {
                let description =
                    FloatingText::new(command_description, "Command Description", true);
                self.spawn_float(description, 80, 80);
            }
        }
    }

    fn get_selected_item_type(&self) -> SelectedItem {
        if self.selected_item_is_up_dir() {
            SelectedItem::UpDir
        } else if self.selected_item_is_dir() {
            SelectedItem::Directory
        } else if self.selected_item_is_cmd() {
            SelectedItem::Command
        } else {
            SelectedItem::None
        }
    }

    fn handle_enter(&mut self) {
        match self.get_selected_item_type() {
            SelectedItem::UpDir => self.enter_parent_directory(),
            SelectedItem::Directory => self.go_to_selected_dir(),
            SelectedItem::Command => {
                if self.selected_commands.is_empty() {
                    if let Some(node) = self.get_selected_node() {
                        self.selected_commands.push(node);
                    }
                }

                if self.skip_confirmation {
                    self.handle_confirm_command();
                } else {
                    let cmd_names = self
                        .selected_commands
                        .iter()
                        .map(|node| node.name.as_str())
                        .collect::<Vec<_>>();

                    let prompt = ConfirmPrompt::new(&cmd_names[..]);
                    self.focus = Focus::ConfirmationPrompt(Float::new(Box::new(prompt), 40, 40));
                }
            }
            SelectedItem::None => {}
        }
    }

    fn handle_confirm_command(&mut self) {
        let commands = self
            .selected_commands
            .iter()
            .map(|node| node.command.clone())
            .collect();

        let command = RunningCommand::new(commands);
        self.spawn_float(command, 80, 80);
        self.selected_commands.clear();
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
        self.visit_stack = vec![(
            self.tabs[self.current_tab.selected().unwrap()]
                .tree
                .root()
                .id(),
            0usize,
        )];
        self.selection.select(Some(0));
        self.filter.clear_search();
        self.update_items();
    }

    fn toggle_task_list_guide(&mut self) {
        self.spawn_float(
            FloatingText::new(ACTIONS_GUIDE.to_string(), "Important Actions Guide", true),
            80,
            80,
        );
    }

    fn scroll_tab_down(&mut self) {
        let len = self.tabs.len();
        let current = self.current_tab.selected().unwrap_or(0);
        let next = if current + 1 >= len { 0 } else { current + 1 };

        self.current_tab.select(Some(next));
        self.refresh_tab();
    }

    fn scroll_tab_up(&mut self) {
        let len = self.tabs.len();
        let current = self.current_tab.selected().unwrap_or(0);
        let next = if current == 0 { len - 1 } else { current - 1 };

        self.current_tab.select(Some(next));
        self.refresh_tab();
    }
}

#[cfg(feature = "tips")]
const TIPS: &str = include_str!("../cool_tips.txt");

#[cfg(feature = "tips")]
fn get_random_tip() -> String {
    let tips: Vec<&str> = TIPS.lines().collect();
    if tips.is_empty() {
        return "".to_string();
    }

    let mut rng = rand::thread_rng();
    let random_index = rng.gen_range(0..tips.len());
    format!(" {} ", tips[random_index])
}

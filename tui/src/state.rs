use crate::{
    confirmation::{ConfirmPrompt, ConfirmStatus},
    dashboard::{self, DashboardLayout},
    filter::{Filter, SearchAction},
    float::{dim_cell, Float, FloatContent},
    floating_text::FloatingText,
    hint::{create_shortcut_list, Shortcut},
    logo::Logo,
    root::check_root_status,
    running_command::RunningCommand,
    script_preview::ScriptPreview,
    shortcuts,
    stars::Starfield,
    system_info::SystemInfo,
    theme::Theme,
    Args,
};
use linutil_core::{ego_tree::NodeId, Command, Config, ConfigValues, ListNode, TabList};
use ratatui::{
    crossterm::event::{KeyCode, KeyEvent, KeyEventKind, KeyModifiers, MouseEvent, MouseEventKind},
    prelude::*,
    widgets::{Block, Clear, HighlightSpacing, List, ListState, Paragraph, Wrap},
};
use std::{
    rc::Rc,
    time::{Duration, Instant},
};
use unicode_width::UnicodeWidthStr;

const MIN_WIDTH: u16 = 90;
const MIN_HEIGHT: u16 = 25;
const FLOAT_SIZE: u16 = 95;
const CONFIRM_PROMPT_FLOAT_SIZE: u16 = 40;
const NOTICE_TIME: Duration = Duration::from_millis(3500);
const RUNNING_COMMAND_FLOAT_WIDTH: u16 = 75;
pub struct AppState {
    /// Areas of tabs
    areas: Option<Areas>,
    /// Selected theme
    theme: Theme,
    /// Short message shown in a popup, and when it appeared
    notice: Option<(String, Instant)>,
    /// Currently focused area
    focus: Focus,
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
    tip: &'static str,
    size_bypass: bool,
    skip_confirmation: bool,
    mouse_enabled: bool,
    system_info: Option<SystemInfo>,
    logo: Option<Logo>,
    stars: Starfield,
}

pub enum Focus {
    Search,
    TabList,
    List,
    ScriptPreview(ScriptPreview),
    FloatingWindow(Float<dyn FloatContent>),
    ConfirmationPrompt(Float<ConfirmPrompt>),
}

pub struct ListEntry {
    pub node: Rc<ListNode>,
    pub id: NodeId,
    pub has_children: bool,
}

struct Areas {
    tab_list: Rect,
    tabs: Vec<Rect>,
    search: Rect,
    list: Rect,
}

enum SelectedItem {
    UpDir,
    Directory,
    Command,
    None,
}

enum ScrollDir {
    Up,
    Down,
}

impl AppState {
    pub fn new(args: Args) -> Self {
        #[cfg(unix)]
        let root_warning = check_root_status(args.bypass_root);
        #[cfg(not(unix))]
        let root_warning = None;

        let tabs = linutil_core::get_tabs(!args.override_validation);
        let root_id = tabs[0].tree.root().id();

        let mut state = Self {
            areas: None,
            theme: args.theme,
            notice: None,
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
            tip: crate::tips::get_random_tip(),
            size_bypass: args.size_bypass,
            skip_confirmation: args.skip_confirmation,
            mouse_enabled: args.mouse,
            system_info: SystemInfo::gather(),
            logo: Logo::load(),
            stars: Starfield::new(),
        };

        #[cfg(unix)]
        if let Some(root_warning) = root_warning {
            state.spawn_float(root_warning, FLOAT_SIZE, FLOAT_SIZE);
        }

        state.update_items();

        if let Some(config_path) = args.config {
            let config = Config::read_config(&config_path, &state.tabs);
            state.apply_config(config);
        }

        state
    }

    fn apply_config(&mut self, config_values: ConfigValues) {
        self.skip_confirmation = self.skip_confirmation || config_values.skip_confirmation;
        self.size_bypass = self.size_bypass || config_values.size_bypass;

        if !config_values.auto_execute_commands.is_empty() {
            self.selected_commands = config_values.auto_execute_commands;
            self.handle_initial_auto_execute();
        }
    }

    fn handle_initial_auto_execute(&mut self) {
        if !self.selected_commands.is_empty() {
            self.spawn_confirmprompt();
        }
    }

    fn spawn_confirmprompt(&mut self) {
        if self.skip_confirmation || self.should_skip_confirmation_for_selection() {
            self.handle_confirm_command();
        } else {
            let cmd_names: Vec<_> = self
                .selected_commands
                .iter()
                .map(|node| node.name.as_str())
                .collect();

            let prompt = ConfirmPrompt::new(&cmd_names);
            self.focus = Focus::ConfirmationPrompt(Float::new(
                Box::new(prompt),
                CONFIRM_PROMPT_FLOAT_SIZE,
                CONFIRM_PROMPT_FLOAT_SIZE,
            ));
        }
    }

    fn should_skip_confirmation_for_selection(&self) -> bool {
        !self.selected_commands.is_empty()
            && self
                .selected_commands
                .iter()
                .all(|node| self.should_skip_confirmation_for_command(&node.command))
    }

    fn should_skip_confirmation_for_command(&self, command: &Command) -> bool {
        match command {
            Command::LocalFile { file, .. } => {
                let path = file.to_string_lossy();
                path.ends_with("/gaming/steam-launcher.sh")
                    || path.ends_with("/gaming/lutris-launcher.sh")
                    || path.ends_with("/gaming/retroarch-launcher.sh")
                    || path.ends_with("/gaming/heroic-launcher.sh")
                    || path.ends_with("/gaming/protonplus.sh")
                    || path.ends_with("/gaming/protonup-qt.sh")
            }
            _ => false,
        }
    }

    fn is_terminal_too_small(&self, terminal_size: Rect) -> bool {
        !self.size_bypass && (terminal_size.height < MIN_HEIGHT || terminal_size.width < MIN_WIDTH)
    }

    pub fn draw(&mut self, frame: &mut Frame) {
        if self.notice_expired() {
            self.notice = None;
        }
        let area = frame.area();
        self.drawable = !self.is_terminal_too_small(area);
        frame.render_widget(
            Block::default().style(
                Style::default()
                    .bg(self.theme.bg())
                    .fg(self.theme.cmd_color()),
            ),
            area,
        );
        if !self.drawable || area.width < 20 || area.height < 12 {
            frame.render_widget(
                Paragraph::new(format!(
                    "Terminal size too small: {}x{}\nMinimum: {}x{} · resize or q to exit",
                    area.width, area.height, MIN_WIDTH, MIN_HEIGHT
                ))
                .wrap(Wrap { trim: true }),
                area,
            );
            // Keep the active command/confirmation visible and responsive during a resize.
            match &mut self.focus {
                Focus::FloatingWindow(float) if area.width >= 4 && area.height >= 4 => {
                    float.draw(frame, area, &self.theme)
                }
                Focus::ConfirmationPrompt(prompt) if area.width >= 4 && area.height >= 4 => {
                    prompt.draw(frame, area, &self.theme)
                }
                _ => {}
            }
            return;
        }
        let initial = DashboardLayout::new(area, 0, 0, 0);
        let panel_width = initial.selection.width.saturating_sub(4);
        let flags = dashboard::legend(dashboard::FLAGS, panel_width, 56, &self.theme);
        let help = dashboard::help_lines(panel_width, &self.theme);
        #[cfg(feature = "tips")]
        let tip = dashboard::tip_lines(self.tip, panel_width, &self.theme);
        #[cfg(not(feature = "tips"))]
        let tip: Vec<Line<'static>> = Vec::new();
        let layout = DashboardLayout::new(
            area,
            flags.len() as u16 + 2,
            help.len() as u16 + 2,
            tip.len() as u16,
        );
        let tabs = self.draw_tabs(frame, area);
        let stars_x = tabs.last().map_or(area.x, |tab| tab.right());
        let stars_area = Rect::new(
            stars_x,
            area.y,
            area.right().saturating_sub(stars_x),
            layout.commands.y.saturating_sub(area.y),
        );
        let current_tab = self
            .current_tab
            .selected()
            .and_then(|index| tabs.get(index).copied())
            .unwrap_or_default();
        let commands = layout.commands;
        let search = Rect::new(
            commands.x + 4,
            commands.y + 2,
            commands.width.saturating_sub(14),
            1,
        );
        let list_area = Rect::new(
            commands.x + 2,
            commands.y + 4,
            commands.width.saturating_sub(4),
            commands.height.saturating_sub(6),
        );
        self.areas = Some(Areas {
            tab_list: Rect::new(area.x, area.y + 1, area.width, 1),
            tabs,
            search,
            list: list_area,
        });
        self.draw_commands(frame, commands, list_area, search);
        if let Focus::ScriptPreview(preview) = &mut self.focus {
            preview.draw(frame, commands, &self.theme);
        }
        self.draw_system_info(frame, layout.system);
        if !layout.logo.is_empty() {
            if let Some(logo) = &mut self.logo {
                logo.draw(frame, layout.logo, &self.theme);
            }
        }
        self.draw_selection(frame, layout.selection);
        for (rect, title, lines) in [
            (layout.flags, " Flags ", flags),
            (layout.help, " Quick Help ", help),
        ] {
            if !rect.is_empty() {
                frame.render_widget(dashboard::block(title, &self.theme, false), rect);
                frame.render_widget(Paragraph::new(lines), rect.inner(Margin::new(2, 1)));
            }
        }
        if !layout.tip.is_empty() {
            frame.render_widget(
                Paragraph::new("Tips")
                    .alignment(Alignment::Center)
                    .style(Style::default().fg(self.theme.tab_color()).bold()),
                Rect::new(layout.tip.x, layout.tip.y - 1, layout.tip.width, 1),
            );
            frame.render_widget(
                Paragraph::new(tip).alignment(Alignment::Center),
                layout.tip.inner(Margin::new(2, 0)),
            );
        }
        if !layout.links.is_empty() {
            let links_area = Rect::new(
                layout.links.x,
                layout.links.y + layout.links.height.saturating_sub(1).min(2),
                layout.links.width,
                1,
            );
            frame.render_widget(
                Paragraph::new("For more info & latest projects visit https://ChrisTitus.com")
                    .alignment(Alignment::Center)
                    .style(dashboard::italic(
                        Style::default().fg(self.theme.focused_color()),
                    )),
                links_area,
            );
        }
        self.stars
            .draw(frame.buffer_mut(), stars_area, layout.logo, &self.theme);
        if matches!(self.focus, Focus::Search) {
            let buffer = frame.buffer_mut();
            for y in area.y..area.bottom() {
                for x in area.x..area.right() {
                    let position = Position::new(x, y);
                    if !layout.commands.contains(position)
                        && !layout.selection.contains(position)
                        && !layout.logo.contains(position)
                        && !layout.links.contains(position)
                        && !current_tab.contains(position)
                    {
                        dim_cell(&mut buffer[(x, y)], &self.theme);
                    }
                }
            }
        }
        match &mut self.focus {
            Focus::FloatingWindow(float) => float.draw_with_undimmed_areas(
                frame,
                area,
                &self.theme,
                &[layout.logo, layout.links],
            ),
            Focus::ConfirmationPrompt(prompt) => prompt.draw_with_undimmed_areas(
                frame,
                area,
                &self.theme,
                &[layout.logo, layout.links],
            ),
            _ => {}
        }
        self.draw_notice(frame, area);
    }

    /// A centred popup that does not take the keyboard: the list stays usable.
    fn draw_notice(&self, frame: &mut Frame, area: Rect) {
        let Some((notice, _)) = &self.notice else {
            return;
        };
        let width = (notice.width() as u16 + 8).min(area.width);
        let height = 5.min(area.height);
        let popup = Rect::new(
            area.x + (area.width - width) / 2,
            area.y + (area.height - height) / 2,
            width,
            height,
        );
        frame.render_widget(Clear, popup);
        frame.render_widget(
            Paragraph::new(vec![Line::default(), Line::from(notice.as_str())])
                .alignment(Alignment::Center)
                .block(dashboard::block("", &self.theme, true)),
            popup,
        );
    }

    fn draw_tabs(&self, frame: &mut Frame, area: Rect) -> Vec<Rect> {
        let available = area.width.saturating_sub(29) as usize;
        let full: Vec<String> = self.tabs.iter().map(|tab| tab.name.clone()).collect();
        let short: Vec<String> = full
            .iter()
            .map(|name| match name.as_str() {
                "Applications Setup" => "Apps Setup".to_string(),
                "System Setup" => "System".to_string(),
                _ => name.clone(),
            })
            .collect();
        let tiny: Vec<String> = short
            .iter()
            .map(|name| match name.as_str() {
                "Apps Setup" => "Apps".to_string(),
                "Utilities" => "Utils".to_string(),
                _ => name.clone(),
            })
            .collect();
        let names = [&full, &short, &tiny]
            .into_iter()
            .find(|names| names.iter().map(|name| name.width() + 5).sum::<usize>() <= available)
            .unwrap_or(&tiny);
        let mut x = area.x;
        let mut tabs = Vec::new();
        for (index, name) in names.iter().enumerate() {
            let label = format!(" {} {} ", index + 1, name);
            let width = (label.width() as u16).min(area.right().saturating_sub(x));
            let rect = Rect::new(x, area.y + 1, width, 1);
            let active = self.current_tab.selected() == Some(index);
            frame.render_widget(
                Paragraph::new(label).style(
                    Style::default()
                        .fg(if active {
                            self.theme.cmd_color()
                        } else {
                            self.theme.tab_unselected()
                        })
                        .bg(if active {
                            self.theme.selection_bg()
                        } else {
                            self.theme.bg()
                        }),
                ),
                rect,
            );
            tabs.push(rect);
            x = x.saturating_add(width + 1).min(area.right());
        }
        tabs
    }

    fn draw_commands(&mut self, frame: &mut Frame, area: Rect, list_area: Rect, search: Rect) {
        let title = if self.multi_select {
            " Directories & Commands [Multi-Select] "
        } else {
            " Directories & Commands "
        };
        frame.render_widget(
            dashboard::block(
                title,
                &self.theme,
                matches!(self.focus, Focus::List | Focus::TabList | Focus::Search),
            ),
            area,
        );
        self.filter.draw_searchbar(frame, search, &self.theme);
        frame.render_widget(
            Paragraph::new("Flag")
                .alignment(Alignment::Right)
                .style(Style::default().fg(self.theme.muted())),
            Rect::new(list_area.right().saturating_sub(4), area.y + 2, 4, 1),
        );
        let mut rows = Vec::new();
        if !self.at_root() {
            rows.push(Line::styled(
                "[D] ..",
                Style::default().fg(self.theme.dir_color()).bold(),
            ));
        }
        let content_width = list_area.width.saturating_sub(2) as usize;
        rows.extend(self.filter.item_list().iter().map(|item| {
            let node = &item.node;
            let chosen = self.selected_commands.contains(node);
            let indicator = if chosen {
                self.theme.multi_select_icon()
            } else {
                ""
            };
            let name = format!(
                "{} {}{}",
                if item.has_children {
                    self.theme.dir_icon()
                } else {
                    self.theme.cmd_icon()
                },
                indicator,
                node.name
            );
            let flag_width = node.task_list.width().min(content_width.saturating_sub(8));
            let name_width = content_width.saturating_sub(flag_width + usize::from(flag_width > 0));
            let name = dashboard::truncate(&name, name_width);
            let padding = content_width.saturating_sub(name.width() + flag_width);
            let color = if self.multi_select && !node.multi_select {
                self.theme.multi_select_disabled_color()
            } else if item.has_children {
                self.theme.dir_color()
            } else {
                self.theme.cmd_color()
            };
            let mut style = Style::default().fg(color);
            if item.has_children || chosen {
                style = style.bold();
            }
            Line::from(vec![
                Span::styled(name, style),
                Span::raw(" ".repeat(padding)),
                Span::styled(
                    dashboard::truncate(&node.task_list, flag_width),
                    Style::default().fg(self.theme.purple()),
                ),
            ])
        }));
        let focused = matches!(self.focus, Focus::List | Focus::TabList);
        let row_count = rows.len();
        let rows = rows.into_iter().enumerate().map(|(index, line)| {
            if index + 1 < row_count {
                Text::from(vec![line, Line::default()])
            } else {
                Text::from(line)
            }
        });
        let list = List::new(rows)
            .highlight_spacing(HighlightSpacing::Always)
            .highlight_symbol(self.theme.tab_icon())
            .highlight_style(
                Style::default()
                    .bg(self.theme.selection_bg())
                    .fg(if focused {
                        self.theme.focused_color()
                    } else {
                        self.theme.cmd_color()
                    }),
            )
            .scroll_padding(1);
        // ListState is also used by the navigation handlers; keep its viewport offset.
        frame.render_stateful_widget(list, list_area, &mut self.selection);
        // Keep the spacer below the selected item free of its highlight background.
        for y in (list_area.y + 1..list_area.bottom()).step_by(2) {
            frame.render_widget(
                Block::default().style(Style::default().bg(self.theme.bg())),
                Rect::new(list_area.x, y, list_area.width, 1),
            );
        }
        let group = if self.filter.is_filtered() {
            "Search results"
        } else {
            self.visit_stack
                .last()
                .and_then(|(id, _)| {
                    self.tabs[self.current_tab.selected().unwrap()]
                        .tree
                        .get(*id)
                })
                .filter(|_| !self.at_root())
                .map(|node| node.value().name.as_str())
                .unwrap_or(
                    self.tabs[self.current_tab.selected().unwrap()]
                        .name
                        .as_str(),
                )
        };
        let footer = format!("{} entries · {}", self.filter.item_list().len(), group);
        let content_width = area.width.saturating_sub(4);
        let footer_width = (footer.width() as u16).min(content_width);
        frame.render_widget(
            Paragraph::new(footer)
                .alignment(Alignment::Right)
                .style(Style::default().fg(self.theme.muted())),
            Rect::new(
                area.right().saturating_sub(2 + footer_width),
                area.bottom().saturating_sub(2),
                footer_width,
                1,
            ),
        );
    }

    fn draw_selection(&self, frame: &mut Frame, area: Rect) {
        if area.is_empty() {
            return;
        }
        frame.render_widget(
            dashboard::block(
                " Details ",
                &self.theme,
                matches!(self.focus, Focus::Search),
            ),
            area,
        );
        let entry = self.selected_entry();
        let (name, description) = if self.selected_item_is_up_dir() {
            ("Parent directory", "Return to the previous directory.")
        } else if let Some(item) = entry {
            (
                item.node.name.as_str(),
                if item.node.description.is_empty() {
                    if item.has_children {
                        "Open this category to browse its commands."
                    } else {
                        "No description available."
                    }
                } else {
                    item.node.description.as_str()
                },
            )
        } else {
            ("No matches", "Try another search.")
        };
        let inner = area.inner(Margin::new(2, 1));
        if inner.is_empty() {
            return;
        }
        let name_offset = u16::from(inner.height > 2);
        if matches!(self.focus, Focus::Search) && !self.filter.is_filtered() {
            frame.render_widget(
                Paragraph::new("Nothing to show, type anything or ESC to close Search")
                    .wrap(Wrap { trim: false })
                    .style(Style::default().fg(self.theme.muted())),
                Rect::new(
                    inner.x,
                    inner.y + name_offset,
                    inner.width,
                    inner.height - name_offset,
                ),
            );
            return;
        }
        frame.render_widget(
            Paragraph::new(name).style(Style::default().fg(self.theme.cmd_color())),
            Rect::new(inner.x, inner.y + name_offset, inner.width, 1),
        );
        if inner.height > 1 + name_offset {
            frame.render_widget(
                Paragraph::new(description)
                    .wrap(Wrap { trim: false })
                    .style(Style::default().fg(self.theme.muted())),
                Rect::new(
                    inner.x,
                    inner.y + 1 + name_offset,
                    inner.width,
                    inner.height.saturating_sub(1 + name_offset),
                ),
            );
        }
    }

    fn selected_entry(&self) -> Option<&ListEntry> {
        let index = self.selection.selected()?;
        let index = if self.at_root() {
            index
        } else {
            index.checked_sub(1)?
        };
        self.filter.item_list().get(index)
    }

    pub fn handle_mouse(&mut self, event: &MouseEvent) -> bool {
        if !self.mouse_enabled {
            return true;
        }
        match &mut self.focus {
            Focus::ScriptPreview(preview) => {
                if self.areas.as_ref().is_some_and(|areas| {
                    areas.list.contains(Position::new(event.column, event.row))
                }) {
                    preview.handle_mouse(event);
                }
                return true;
            }
            Focus::FloatingWindow(float) => {
                float.handle_mouse_event(event);
                return true;
            }
            Focus::ConfirmationPrompt(confirm) => {
                confirm.content.handle_mouse_event(event);
                return true;
            }
            _ => {}
        }
        if !self.drawable {
            return true;
        }
        let Some(areas) = &self.areas else {
            return true;
        };
        let position = Position::new(event.column, event.row);
        let in_tabs = areas.tab_list.contains(position);
        let in_list = areas.list.contains(position);
        let in_search = areas.search.contains(position);
        let tab = areas.tabs.iter().position(|rect| rect.contains(position));
        match event.kind {
            MouseEventKind::Down(ratatui::crossterm::event::MouseButton::Left) if in_search => {
                self.enter_search()
            }
            MouseEventKind::Down(ratatui::crossterm::event::MouseButton::Left) if tab.is_some() => {
                self.current_tab.select(tab);
                self.refresh_tab();
                self.focus = Focus::List;
            }
            MouseEventKind::Moved if !matches!(self.focus, Focus::Search) => {
                if in_list {
                    self.focus = Focus::List;
                } else if in_tabs {
                    self.focus = Focus::TabList;
                }
            }
            MouseEventKind::ScrollDown if !matches!(self.focus, Focus::Search) => {
                if in_tabs {
                    self.scroll_tab_down();
                } else if in_list {
                    self.scroll_down();
                }
            }
            MouseEventKind::ScrollUp if !matches!(self.focus, Focus::Search) => {
                if in_tabs {
                    self.scroll_tab_up();
                } else if in_list {
                    self.scroll_up();
                }
            }
            _ => {}
        }
        true
    }

    pub fn handle_key(&mut self, key: &KeyEvent) -> bool {
        // This should be defined first to allow closing
        // the application even when not drawable ( If terminal is small )
        // Exit on 'q' or 'Ctrl-c' input
        if matches!(self.focus, Focus::TabList | Focus::List)
            && (matches!(key.code, KeyCode::Char('q'))
                || key.modifiers.contains(KeyModifiers::CONTROL)
                    && matches!(key.code, KeyCode::Char('c' | 'C')))
        {
            return false;
        }

        if let Focus::ScriptPreview(preview) = &mut self.focus {
            if preview.handle_key(key) {
                self.focus = Focus::List;
            }
            return true;
        }
        // Commands and confirmation remain responsive even below the dashboard minimum.
        if !self.drawable
            && !matches!(
                self.focus,
                Focus::FloatingWindow(_) | Focus::ConfirmationPrompt(_) | Focus::Search
            )
        {
            return true;
        }

        // Handle key only when Tablist or List is focused
        // Prevents exiting the application even when a command is running
        // Add keys here which should work on both TabList and List
        if matches!(self.focus, Focus::TabList | Focus::List)
            && self.handle_tablist_and_list_keys(key)
        {
            return true;
        }

        if let Focus::FloatingWindow(command) = &mut self.focus {
            if command.handle_key_event(key) {
                self.focus = Focus::List;
            }
            return true;
        }

        match &mut self.focus {
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
                KeyCode::Enter | KeyCode::Right => self.focus = Focus::List,
                KeyCode::Char('j') | KeyCode::Down => self.scroll_tab_down(),
                KeyCode::Char('k') | KeyCode::Up => self.scroll_tab_up(),

                _ => {}
            },

            Focus::List if key.kind != KeyEventKind::Release => match key.code {
                KeyCode::Char('j') | KeyCode::Down => self.scroll_down(),
                KeyCode::Char('k') | KeyCode::Up => self.scroll_up(),
                KeyCode::Char('p') => self.enable_preview(),
                KeyCode::Char('d') => self.enable_description(),
                KeyCode::Enter | KeyCode::Right => self.handle_enter(),
                KeyCode::Char('h') | KeyCode::Left => self.go_back(),
                KeyCode::Char(' ') if self.multi_select => self.toggle_selection(),
                _ => {}
            },

            _ => (),
        };
        true
    }

    pub fn needs_animation_frame(&self) -> bool {
        matches!(&self.focus, Focus::FloatingWindow(float) if float.content.result_pending())
            || self.drawable
                && (self.notice_expired()
                    || matches!(
                        self.focus,
                        Focus::List | Focus::TabList | Focus::Search | Focus::ScriptPreview(_)
                    ) && self.stars.frame_due(&self.theme))
    }

    fn notice_expired(&self) -> bool {
        self.notice
            .as_ref()
            .is_some_and(|(_, shown)| shown.elapsed() >= NOTICE_TIME)
    }

    /// On a terminal without truecolor every theme looks the same, so `t` only
    /// says why nothing changes.
    fn cycle_theme(&mut self, truecolor: bool) {
        let notice = if truecolor {
            self.theme.next();
            format!("{} Theme applied", self.theme.name())
        } else {
            "Themes need a truecolor terminal".to_string()
        };
        self.notice = Some((notice, Instant::now()));
    }

    fn handle_tablist_and_list_keys(&mut self, key: &KeyEvent) -> bool {
        match key.code {
            KeyCode::Tab => self.scroll_tab_down(),
            KeyCode::BackTab => self.scroll_tab_up(),
            KeyCode::Char('/') => self.enter_search(),
            KeyCode::Char('?') => self.enable_help(),
            KeyCode::Char(c @ '1'..='9') => {
                let index = (c as u8 - b'1') as usize;
                if index < self.tabs.len() {
                    self.current_tab.select(Some(index));
                    self.refresh_tab();
                    self.focus = Focus::List;
                }
            }
            KeyCode::Char('v') => self.toggle_multi_select(),
            KeyCode::Char('t') => self.cycle_theme(crate::theme::truecolor()),
            KeyCode::Char('s') if key.modifiers.is_empty() => self.stars.toggle(),
            _ => return false,
        }
        true
    }

    fn scroll(&mut self, direction: ScrollDir) {
        let Some(selected) = self.selection.selected() else {
            return;
        };
        let list_len = if !self.at_root() {
            self.filter.item_list().len() + 1
        } else {
            self.filter.item_list().len()
        };

        if list_len == 0 {
            return;
        };

        let next_selection = match direction {
            ScrollDir::Up if selected == 0 => list_len - 1,
            ScrollDir::Down if selected >= list_len - 1 => 0,
            ScrollDir::Up => selected - 1,
            ScrollDir::Down => selected + 1,
        };
        self.selection.select(Some(next_selection));
    }

    fn scroll_up(&mut self) {
        self.scroll(ScrollDir::Up)
    }

    fn scroll_down(&mut self) {
        self.scroll(ScrollDir::Down)
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

        let len = self.filter.item_list().len() + usize::from(!self.at_root());
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
        if !self.at_root() {
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
        self.selected_entry()
            .filter(|item| !item.has_children)
            .map(|item| item.node.clone())
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

        if !self.at_root() {
            if selected_index == 0 {
                return false;
            } else {
                selected_index = selected_index.saturating_sub(1);
            }
        }

        self.filter
            .item_list()
            .get(selected_index)
            .is_some_and(|i| i.has_children)
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
            self.focus = Focus::ScriptPreview(ScriptPreview::new(
                &list_node.command,
                &list_node.name,
                &self.theme,
            ));
        }
    }

    fn enable_description(&mut self) {
        if let Some(command_description) = self.get_selected_description() {
            if !command_description.is_empty() {
                let description =
                    FloatingText::new(command_description, "Command Description", true)
                        .with_close_key('d');
                self.spawn_float(description, FLOAT_SIZE, FLOAT_SIZE);
            }
        }
    }

    fn enable_help(&mut self) {
        let mut lines = vec![
            Line::styled(
                "Lowercase shortcuts only · running commands accept normal input",
                Style::default().fg(self.theme.muted()),
            ),
            Line::default(),
            Line::styled(
                "Navigation",
                Style::default().fg(self.theme.tab_color()).bold(),
            ),
        ];
        // The same list wherever the help is opened; it fills two columns
        // row by row, so pairs (tab/shift+tab, v/space) stay stacked.
        let mut shortcuts = shortcuts!(
            ("Quit Linutil", ["q", "ctrl+c"]),
            ("Open/run", ["enter", "right"]),
            ("Select item above", ["k", "up"]),
            ("Select item below", ["j", "down"]),
            ("Parent directory", ["h", "left"]),
            ("Script preview", ["p"]),
            ("Command description", ["d"]),
            ("Search", ["/"]),
            ("Cycle theme", ["t"]),
            ("Toggle stars", ["s"]),
            ("Next tab", ["tab"]),
            ("Multi-selection mode", ["v"]),
            ("Previous tab", ["shift+tab"]),
            ("Select command (multi-select)", ["space"]),
        )
        .into_vec();
        // Number keys reach the first nine tabs.
        let categories = self.tabs.len().min(9);
        shortcuts.push(Shortcut::new(
            "Jump to category",
            [if categories > 1 {
                format!("1..{categories}")
            } else {
                "1".to_string()
            }],
        ));
        for mut line in create_shortcut_list(shortcuts, 88).into_vec() {
            for span in &mut line.spans {
                span.style = span
                    .style
                    .fg(if span.style.add_modifier.contains(Modifier::BOLD) {
                        self.theme.purple()
                    } else {
                        self.theme.muted()
                    });
            }
            lines.push(line);
        }
        let sections: &[(&str, &[(&str, &str)])] = &[
            (
                "Search",
                &[
                    ("left/right", "Move cursor"),
                    ("backspace/delete", "Delete previous/next character"),
                    ("tab", "Complete search"),
                    ("enter", "Keep query and return to results"),
                    ("esc", "Clear query and return to list"),
                ],
            ),
            (
                "Script preview",
                &[
                    ("j/k or up/down", "Scroll; pageup/pagedown moves 10 lines"),
                    ("home/end", "First/last line; long lines wrap"),
                    ("p/esc", "Close preview"),
                ],
            ),
            (
                "Description",
                &[("j/k or up/down", "Scroll"), ("d/esc", "Close description")],
            ),
            (
                "Confirmation",
                &[("y", "Continue"), ("n/q/esc", "Abort; up/down scrolls")],
            ),
            (
                "Running command",
                &[
                    ("ctrl+c", "Cancel; press again to escalate"),
                    ("pageup/pagedown", "Scroll; other keys go to the command"),
                ],
            ),
            (
                "Finished command",
                &[
                    ("any key", "Close"),
                    ("l", "Save log; pageup/pagedown scrolls"),
                ],
            ),
        ];
        for (title, shortcuts) in sections {
            lines.push(Line::default());
            lines.push(Line::styled(
                *title,
                Style::default().fg(self.theme.tab_color()).bold(),
            ));
            for (key, meaning) in *shortcuts {
                lines.push(Line::from(vec![
                    Span::styled(
                        format!("{key:<24}"),
                        Style::default().fg(self.theme.purple()),
                    ),
                    Span::styled(*meaning, Style::default().fg(self.theme.muted())),
                ]));
            }
        }
        let height = (lines.len() as u16 + 4).min(44);
        self.focus = Focus::FloatingWindow(Float::capped(
            Box::new(
                FloatingText::from_text(Text::from(lines), " Help ", true)
                    .with_footer(" Esc to close ")
                    .with_close_key('?'),
            ),
            94,
            height,
        ));
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
                self.spawn_confirmprompt();
            }
            SelectedItem::None => {}
        }
    }

    fn handle_confirm_command(&mut self) {
        let commands: Vec<&Command> = self
            .selected_commands
            .iter()
            .map(|node| &node.command)
            .collect();

        let command = RunningCommand::new(&commands);
        self.focus = Focus::FloatingWindow(
            Float::<dyn FloatContent>::new(
                Box::new(command),
                RUNNING_COMMAND_FLOAT_WIDTH,
                FLOAT_SIZE,
            )
            .with_horizontal_inset(3),
        );
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
        self.filter.deactivate_search();
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

    fn scroll_tab_down(&mut self) {
        if self.current_tab.selected().unwrap() == self.tabs.len() - 1 {
            self.current_tab.select_first();
        } else {
            self.current_tab.select_next();
        }
        self.refresh_tab();
    }

    fn scroll_tab_up(&mut self) {
        if self.current_tab.selected().unwrap() == 0 {
            self.current_tab.select(Some(self.tabs.len() - 1));
        } else {
            self.current_tab.select_previous();
        }
        self.refresh_tab();
    }

    fn draw_system_info(&self, frame: &mut Frame, area: Rect) {
        if area.is_empty() {
            return;
        }
        frame.render_widget(dashboard::block(" System ", &self.theme, false), area);
        let Some(info) = &self.system_info else {
            return;
        };
        let inner = area.inner(Margin::new(2, 1));
        let lines = info.render_lines(&self.theme, inner.width as usize);
        let rows = Layout::vertical(vec![Constraint::Length(1); info.entries_len()])
            .flex(ratatui::layout::Flex::SpaceBetween)
            .split(inner);
        for (line, row) in lines.into_iter().zip(rows.iter()) {
            frame.render_widget(Paragraph::new(line), *row);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::running_command::RESULT_KEY_PAUSE;
    use ratatui::{backend::TestBackend, crossterm::event::MouseButton, Terminal};

    fn app() -> AppState {
        AppState::new(Args {
            config: None,
            theme: Theme::Default,
            skip_confirmation: false,
            override_validation: true,
            size_bypass: false,
            mouse: true,
            bypass_root: true,
        })
    }

    fn key(app: &mut AppState, code: KeyCode) {
        assert!(app.handle_key(&KeyEvent::new(code, KeyModifiers::NONE)));
    }

    fn draw(app: &mut AppState, width: u16, height: u16) -> String {
        let mut terminal = Terminal::new(TestBackend::new(width, height)).unwrap();
        terminal.draw(|frame| app.draw(frame)).unwrap();
        let buffer = terminal.backend().buffer();
        (0..height)
            .map(|y| {
                (0..width)
                    .map(|x| buffer[(x, y)].symbol())
                    .collect::<String>()
            })
            .collect::<Vec<_>>()
            .join("\n")
    }

    #[test]
    fn catalog_navigation_preview_and_confirmation_use_real_scripts_without_execution() {
        let mut app = app();
        draw(&mut app, 200, 50);
        assert!(app.selected_entry().unwrap().has_children);
        assert!(draw(&mut app, 200, 50).contains("Communication Apps"));
        key(&mut app, KeyCode::Enter);
        key(&mut app, KeyCode::Down); // Skip synthetic parent entry.
        let selected = app.get_selected_node().unwrap();
        assert_eq!(selected.name, "Discord");
        key(&mut app, KeyCode::Char('p'));
        let rendered = draw(&mut app, 200, 50);
        assert!(rendered.contains("Script Preview"));
        assert!(rendered.contains("discord-setup.sh"));
        assert!(rendered.contains("Details"));
        key(&mut app, KeyCode::Esc);
        assert_eq!(app.get_selected_node().unwrap().name, "Discord");
        key(&mut app, KeyCode::Enter);
        assert!(matches!(app.focus, Focus::ConfirmationPrompt(_)));
        assert_eq!(app.selected_commands.len(), 1);
        key(&mut app, KeyCode::Char('n'));
        assert!(app.selected_commands.is_empty());
        assert!(matches!(app.focus, Focus::List));
        key(&mut app, KeyCode::Char('h'));
        assert!(app.at_root());
    }

    #[test]
    fn global_search_and_batch_confirmation_preserve_selected_commands() {
        let mut app = app();
        draw(&mut app, 200, 50);
        key(&mut app, KeyCode::Char('/'));
        for c in "lynis".chars() {
            key(&mut app, KeyCode::Char(c));
        }
        key(&mut app, KeyCode::Enter);
        assert_eq!(
            app.get_selected_node().unwrap().name,
            "Lynis Security Audit"
        );
        assert_eq!(app.current_tab.selected(), Some(0));
        key(&mut app, KeyCode::Char('p'));
        assert!(draw(&mut app, 200, 50).contains("lynis"));
        key(&mut app, KeyCode::Char('p'));
        key(&mut app, KeyCode::Char('/'));
        key(&mut app, KeyCode::Esc);
        key(&mut app, KeyCode::Enter);
        key(&mut app, KeyCode::Down);
        key(&mut app, KeyCode::Char('v'));
        key(&mut app, KeyCode::Char(' '));
        key(&mut app, KeyCode::Down);
        key(&mut app, KeyCode::Char(' '));
        assert_eq!(app.selected_commands.len(), 2);
        key(&mut app, KeyCode::Enter);
        assert!(matches!(app.focus, Focus::ConfirmationPrompt(_)));
        // Cancellation must remain reachable after shrinking below the dashboard minimum.
        draw(&mut app, 50, 10);
        assert!(!app.drawable);
        key(&mut app, KeyCode::Esc);
        assert!(matches!(app.focus, Focus::List));
        assert_eq!(app.selected_commands.len(), 2);
    }

    #[test]
    fn dashboard_renders_across_compact_full_and_bypassed_sizes() {
        let mut app = app();
        for (width, height) in [
            (90, 25),
            (90, 40),
            (100, 25),
            (147, 40),
            (176, 48),
            (200, 50),
            (225, 49),
            (250, 53),
        ] {
            let rendered = draw(&mut app, width, height);
            assert!(
                rendered.contains("Directories & Commands"),
                "{width}×{height}"
            );
            assert!(rendered.contains("Details"));
            assert!(rendered.contains("System"));
            if width >= 147 && height >= 40 {
                assert!(rendered.contains("Help"));
            }
        }
        app.size_bypass = true;
        for (width, height) in [(0, 0), (1, 1), (15, 8), (30, 15), (60, 20)] {
            draw(&mut app, width, height);
        }
        app.size_bypass = false;
        draw(&mut app, 200, 50);
        key(&mut app, KeyCode::Char('?'));
        assert!(draw(&mut app, 200, 50).contains("─ Help ─"));
        key(&mut app, KeyCode::Esc);
        app.cycle_theme(true);
        assert_eq!(app.theme, Theme::Nord);
        let text = draw(&mut app, 200, 50);
        let (row, line) = text
            .lines()
            .enumerate()
            .find(|(_, line)| line.contains("Nord Theme applied"))
            .unwrap();
        let column = line.split("Nord").next().unwrap().chars().count();
        assert_eq!(row, 24);
        assert_eq!(column, (200 - "Nord Theme applied".len()) / 2);
    }

    #[test]
    fn theme_notice_expires_and_needs_truecolor() {
        let mut app = app();
        draw(&mut app, 200, 50);
        app.cycle_theme(false);
        assert_eq!(app.theme, Theme::Default);
        assert!(draw(&mut app, 200, 50).contains("Themes need a truecolor terminal"));
        app.notice = Some(("gone".to_string(), Instant::now() - NOTICE_TIME));
        assert!(app.needs_animation_frame());
        assert!(!draw(&mut app, 200, 50).contains("gone"));
        assert!(app.notice.is_none());
    }

    #[test]
    fn empty_search_prompt_and_dimming_follow_search_lifecycle() {
        let mut app = app();
        app.mouse_enabled = false;
        let mut terminal = Terminal::new(TestBackend::new(200, 50)).unwrap();
        terminal.draw(|frame| app.draw(frame)).unwrap();
        let baseline = terminal.backend().buffer().clone();
        let right_x = app.areas.as_ref().unwrap().list.right() + 3;
        key(&mut app, KeyCode::Char('/'));
        terminal.draw(|frame| app.draw(frame)).unwrap();
        let search = terminal.backend().buffer();
        assert_ne!(search[(right_x, 3)].fg, baseline[(right_x, 3)].fg);
        assert_eq!(search[(0, 5)].fg, baseline[(0, 5)].fg);
        assert_eq!(search[(right_x, 12)].fg, app.theme.focused_color());
        assert_ne!(search[(right_x, 12)].fg, baseline[(right_x, 12)].fg);
        let tabs = &app.areas.as_ref().unwrap().tabs;
        let (current, other) = (tabs[0], tabs[1]);
        assert_eq!(app.current_tab.selected(), Some(0));
        assert_eq!(
            search[(current.x + 1, current.y)],
            baseline[(current.x + 1, current.y)]
        );
        assert_ne!(
            search[(other.x + 1, other.y)].fg,
            baseline[(other.x + 1, other.y)].fg
        );
        let logo = DashboardLayout::new(Rect::new(0, 0, 200, 50), 0, 0, 0).logo;
        for y in logo.y..logo.bottom() {
            for x in logo.x..logo.right() {
                assert_eq!(search[(x, y)], baseline[(x, y)]);
            }
        }
        let text = draw(&mut app, 200, 50);
        assert!(text.contains("Nothing to show,"));
        assert!(text.contains("type anything or ESC to close Search"));
        assert!(!text.contains("No matches"));
        for c in "ghostty".chars() {
            key(&mut app, KeyCode::Char(c));
        }
        assert!(draw(&mut app, 200, 50).contains("Ghostty is"));
        for _ in 0..7 {
            key(&mut app, KeyCode::Backspace);
        }
        assert!(draw(&mut app, 200, 50).contains("Nothing to show,"));
        key(&mut app, KeyCode::Esc);
        terminal.draw(|frame| app.draw(frame)).unwrap();
        assert_eq!(
            terminal.backend().buffer()[(right_x, 3)].fg,
            baseline[(right_x, 3)].fg
        );
        assert!(!draw(&mut app, 200, 50).contains("Nothing to show,"));
        key(&mut app, KeyCode::Char('?'));
        terminal.draw(|frame| app.draw(frame)).unwrap();
        for y in logo.y..logo.bottom() {
            for x in logo.x..logo.right() {
                assert_eq!(terminal.backend().buffer()[(x, y)], baseline[(x, y)]);
            }
        }
    }

    #[test]
    fn stars_toggle_only_in_navigation_and_are_listed_in_help() {
        let mut app = app();
        app.stars = Starfield::for_terminal("xterm-256color", "truecolor", false);
        draw(&mut app, 200, 50);
        assert!(app.stars.active(&app.theme));
        key(&mut app, KeyCode::Char('S'));
        assert!(app.stars.active(&app.theme));
        assert!(app.handle_key(&KeyEvent::new(KeyCode::Char('s'), KeyModifiers::CONTROL)));
        assert!(app.stars.active(&app.theme));
        key(&mut app, KeyCode::Char('s'));
        assert!(!app.stars.active(&app.theme));
        key(&mut app, KeyCode::Char('s'));
        assert!(app.stars.active(&app.theme));
        key(&mut app, KeyCode::Char('/'));
        key(&mut app, KeyCode::Char('s'));
        assert!(matches!(app.focus, Focus::Search));
        assert!(app.stars.active(&app.theme));
        std::thread::sleep(std::time::Duration::from_millis(80));
        assert!(app.needs_animation_frame());
        key(&mut app, KeyCode::Esc);
        key(&mut app, KeyCode::Char('?'));
        assert!(draw(&mut app, 200, 50).contains("Toggle stars"));
        key(&mut app, KeyCode::Char('s'));
        assert!(matches!(app.focus, Focus::FloatingWindow(_)));
        assert!(app.stars.active(&app.theme));
        assert!(!app.needs_animation_frame());

        // The stars keep twinkling beside the script preview.
        key(&mut app, KeyCode::Esc);
        key(&mut app, KeyCode::Char('/'));
        for c in "Lynis".chars() {
            key(&mut app, KeyCode::Char(c));
        }
        key(&mut app, KeyCode::Enter);
        key(&mut app, KeyCode::Char('p'));
        assert!(matches!(app.focus, Focus::ScriptPreview(_)));
        draw(&mut app, 200, 50);
        std::thread::sleep(std::time::Duration::from_millis(80));
        assert!(app.needs_animation_frame());
    }

    #[test]
    fn help_is_the_same_everywhere_and_l_does_not_open() {
        let mut app = app();
        let rendered = draw(&mut app, 200, 50);
        assert!(rendered.contains("enter/right"));
        assert!(!rendered.contains("Full help"));
        assert!(rendered.lines().any(|line| {
            let words: Vec<&str> = line.split_whitespace().collect();
            words.windows(2).any(|pair| pair == ["?", "Help"])
        }));
        assert!(rendered.contains("Quit Linutil"));
        assert!(!rendered.contains("enter/l/right"));

        assert!(app.at_root());
        key(&mut app, KeyCode::Char('l'));
        assert!(app.at_root());

        let column = |rows: &[&str], label: &str| {
            rows.iter()
                .enumerate()
                .find_map(|(y, row)| row.find(label).map(|x| (y, row[..x].chars().count())))
        };
        for open_folder in [false, true] {
            if open_folder {
                key(&mut app, KeyCode::Enter);
                assert!(!app.at_root());
            }
            key(&mut app, KeyCode::Char('?'));
            let rendered = draw(&mut app, 200, 50);
            let rows: Vec<&str> = rendered.lines().collect();
            assert!(rendered.contains("[q] [ctrl+c] Quit Linutil"));
            assert!(!rendered.contains("[?]"));
            assert!(!rendered.contains("[l]"));
            let (tab_y, tab_x) = column(&rows, "[tab] Next tab").unwrap();
            let (v_y, v_x) = column(&rows, "[v] Multi-selection mode").unwrap();
            assert_eq!(column(&rows, "[shift+tab]"), Some((tab_y + 1, tab_x)));
            assert_eq!(column(&rows, "[space]"), Some((v_y + 1, v_x)));
            assert_eq!(tab_y, v_y);
            assert!(rendered.contains(&format!("[1..{}] Jump to category", app.tabs.len())));
            key(&mut app, KeyCode::Esc);
        }
    }

    #[test]
    fn windows_close_with_their_own_key_or_esc() {
        let mut app = app();
        draw(&mut app, 200, 50);
        let floating = |app: &AppState| matches!(app.focus, Focus::FloatingWindow(_));

        key(&mut app, KeyCode::Char('?'));
        assert!(draw(&mut app, 200, 50).contains("─ Help ─"));
        for other in [KeyCode::Enter, KeyCode::Char('q'), KeyCode::Char('d')] {
            key(&mut app, other);
            assert!(floating(&app));
        }
        key(&mut app, KeyCode::Char('?'));
        assert!(!floating(&app));

        key(&mut app, KeyCode::Enter);
        key(&mut app, KeyCode::Down); // Skip synthetic parent entry.
        key(&mut app, KeyCode::Char('d'));
        assert!(floating(&app));
        for other in [KeyCode::Enter, KeyCode::Char('q'), KeyCode::Char('?')] {
            key(&mut app, other);
            assert!(floating(&app));
        }
        key(&mut app, KeyCode::Char('d'));
        assert!(!floating(&app));
        key(&mut app, KeyCode::Char('d'));
        key(&mut app, KeyCode::Esc);
        assert!(!floating(&app));
    }

    #[test]
    fn left_at_root_keeps_list_navigation_spacing_and_highlight() {
        let mut app = app();
        draw(&mut app, 200, 50);
        key(&mut app, KeyCode::Left);
        let mut terminal = Terminal::new(TestBackend::new(200, 50)).unwrap();
        terminal.draw(|frame| app.draw(frame)).unwrap();
        let list = app.areas.as_ref().unwrap().list;
        let buffer = terminal.backend().buffer();
        assert_eq!(buffer[(list.x - 2, list.y)].fg, app.theme.focused_color());
        assert_eq!(buffer[(list.x, list.y)].fg, app.theme.focused_color());
        assert_eq!(buffer[(list.x + 2, list.y)].fg, app.theme.focused_color());
        for x in list.x..list.right() {
            assert_eq!(buffer[(x, list.y + 1)].symbol(), " ");
            assert_eq!(buffer[(x, list.y + 1)].bg, app.theme.bg());
        }
        assert!(matches!(app.focus, Focus::List));
        let tab = app.current_tab.selected();
        let selected = app.selection.selected().unwrap();
        key(&mut app, KeyCode::Down);
        assert_eq!(app.selection.selected(), Some(selected + 1));
        key(&mut app, KeyCode::Up);
        assert_eq!(app.selection.selected(), Some(selected));
        assert_eq!(app.current_tab.selected(), tab);
        key(&mut app, KeyCode::Right);
        assert!(!app.at_root());
        key(&mut app, KeyCode::Left);
        assert!(app.at_root());
        assert!(matches!(app.focus, Focus::List));
        for _ in 0..app.filter.item_list().len() {
            key(&mut app, KeyCode::Down);
        }
        let name = app.selected_entry().unwrap().node.name.clone();
        assert!(draw(&mut app, 90, 25).contains(&name));
    }

    #[test]
    fn mouse_regions_numbered_tabs_and_parent_position_stay_consistent() {
        let mut app = app();
        draw(&mut app, 200, 50);
        key(&mut app, KeyCode::Char('4'));
        assert_eq!(app.current_tab.selected(), Some(3));
        draw(&mut app, 200, 50);
        let first_tab = app.areas.as_ref().unwrap().tabs[0];
        app.handle_mouse(&MouseEvent {
            kind: MouseEventKind::Down(MouseButton::Left),
            column: first_tab.x + 1,
            row: first_tab.y,
            modifiers: KeyModifiers::NONE,
        });
        assert_eq!(app.current_tab.selected(), Some(0));
        key(&mut app, KeyCode::Enter);
        let last = app.filter.item_list().len();
        app.selection.select(Some(last));
        app.update_items();
        assert_eq!(app.selection.selected(), Some(last));
        assert!(app.get_selected_node().is_some());
        draw(&mut app, 200, 50);
        let search = app.areas.as_ref().unwrap().search;
        app.handle_mouse(&MouseEvent {
            kind: MouseEventKind::Down(MouseButton::Left),
            column: search.x,
            row: search.y,
            modifiers: KeyModifiers::NONE,
        });
        assert!(matches!(app.focus, Focus::Search));
        let second_tab = app.areas.as_ref().unwrap().tabs[1];
        app.handle_mouse(&MouseEvent {
            kind: MouseEventKind::Down(MouseButton::Left),
            column: second_tab.x + 1,
            row: second_tab.y,
            modifiers: KeyModifiers::NONE,
        });
        assert!(matches!(app.focus, Focus::List));
        let rendered = draw(&mut app, 200, 50);
        assert!(rendered.contains("/ Search"));
    }

    #[test]
    fn confirmation_runs_harmless_interactive_pty_fixture_and_returns_to_dashboard() {
        use std::time::{Duration, Instant};
        let mut app = app();
        app.stars = Starfield::for_terminal("xterm-256color", "truecolor", false);
        draw(&mut app, 200, 50);
        app.selected_commands.push(Rc::new(ListNode {
            name: "PTY fixture".to_string(), description: String::new(),
            command: Command::Raw("printf 'phase1 ready\\n'; IFS= read -r answer; printf 'received:%s\\n' \"$answer\"".to_string()),
            task_list: String::new(), multi_select: false,
        }));
        app.spawn_confirmprompt();
        assert!(matches!(app.focus, Focus::ConfirmationPrompt(_)));
        key(&mut app, KeyCode::Char('y'));
        let deadline = Instant::now() + Duration::from_secs(5);
        while !draw(&mut app, 200, 50).contains("phase1 ready") {
            assert!(
                Instant::now() < deadline,
                "PTY fixture did not become ready"
            );
            std::thread::sleep(Duration::from_millis(10));
        }
        for c in "heXllos".chars() {
            key(&mut app, KeyCode::Char(c));
        }
        key(&mut app, KeyCode::Enter);
        loop {
            let rendered = draw(&mut app, 200, 50);
            if rendered.contains(" Success ") && rendered.contains("received:heXllos") {
                break;
            }
            assert!(
                Instant::now() < deadline,
                "PTY fixture did not finish successfully"
            );
            std::thread::sleep(Duration::from_millis(10));
        }
        std::thread::sleep(RESULT_KEY_PAUSE);
        key(&mut app, KeyCode::Enter);
        assert!(matches!(app.focus, Focus::List));
        assert!(app.stars.active(&app.theme));
        assert!(draw(&mut app, 200, 50).contains("Directories & Commands"));
    }

    #[test]
    fn failed_command_does_not_show_success_completion_message() {
        use std::time::{Duration, Instant};
        let mut app = app();
        draw(&mut app, 200, 50);
        app.selected_commands.push(Rc::new(ListNode {
            name: "Failure fixture".to_string(),
            description: String::new(),
            command: Command::Raw("printf 'fixture failed\\n'; exit 1".to_string()),
            task_list: String::new(),
            multi_select: false,
        }));
        app.spawn_confirmprompt();
        key(&mut app, KeyCode::Char('y'));
        let deadline = Instant::now() + Duration::from_secs(5);
        loop {
            let rendered = draw(&mut app, 200, 50);
            if rendered.contains(" Fail ") {
                assert!(!rendered.contains("Done! Press any key to close . . ."));
                break;
            }
            assert!(Instant::now() < deadline, "PTY fixture did not finish");
            std::thread::sleep(Duration::from_millis(10));
        }
        std::thread::sleep(RESULT_KEY_PAUSE);
        key(&mut app, KeyCode::Enter);
        assert!(matches!(app.focus, Focus::List));
    }

    #[test]
    fn shortcuts_are_lowercase_only_but_search_accepts_uppercase() {
        let mut app = app();
        draw(&mut app, 200, 50);

        // Search allows typing uppercase letters
        key(&mut app, KeyCode::Char('/'));
        for c in "Lynis".chars() {
            key(&mut app, KeyCode::Char(c));
        }
        key(&mut app, KeyCode::Enter);
        assert_eq!(
            app.get_selected_node().unwrap().name,
            "Lynis Security Audit"
        );

        // Shortcuts are lowercase only
        key(&mut app, KeyCode::Char('P'));
        assert!(matches!(app.focus, Focus::List));
        key(&mut app, KeyCode::Char('p'));
        assert!(matches!(app.focus, Focus::ScriptPreview(_)));
        key(&mut app, KeyCode::Esc);
        assert!(matches!(app.focus, Focus::List));

        // 'N' and 'Y' do nothing; 'n' aborts the confirmation prompt
        app.selected_commands.push(app.get_selected_node().unwrap());
        app.spawn_confirmprompt();
        assert!(matches!(app.focus, Focus::ConfirmationPrompt(_)));
        let confirm_rendered = draw(&mut app, 200, 50);
        assert!(confirm_rendered.contains("[y] to continue [n] to cancel"));
        key(&mut app, KeyCode::Char('N'));
        key(&mut app, KeyCode::Char('Y'));
        assert!(matches!(app.focus, Focus::ConfirmationPrompt(_)));
        key(&mut app, KeyCode::Char('n'));
        assert!(matches!(app.focus, Focus::List));

        // Esc aborts confirmation prompt
        app.selected_commands.push(app.get_selected_node().unwrap());
        app.spawn_confirmprompt();
        assert!(matches!(app.focus, Focus::ConfirmationPrompt(_)));
        key(&mut app, KeyCode::Esc);
        assert!(matches!(app.focus, Focus::List));

        // 'y' confirms the confirmation prompt
        app.selected_commands.push(Rc::new(ListNode {
            name: "Echo fixture".to_string(),
            description: String::new(),
            command: Command::Raw("exit 0".to_string()),
            task_list: String::new(),
            multi_select: false,
        }));
        app.spawn_confirmprompt();
        assert!(matches!(app.focus, Focus::ConfirmationPrompt(_)));
        key(&mut app, KeyCode::Char('y'));
        assert!(matches!(app.focus, Focus::FloatingWindow(_)));
    }

    #[test]
    fn ctrl_c_cancels_running_command_and_quits_only_from_main_view() {
        use std::time::{Duration, Instant};
        let mut app = app();
        draw(&mut app, 200, 50);

        // In main view (Focus::List), Ctrl+C exits linutil (handle_key returns false)
        assert!(!app.handle_key(&KeyEvent::new(KeyCode::Char('c'), KeyModifiers::CONTROL)));

        app.selected_commands.push(Rc::new(ListNode {
            name: "Loop fixture".to_string(),
            description: String::new(),
            command: Command::Raw(
                "trap 'exit 130' INT; printf 'loop started\\n'; while true; do sleep 1; done"
                    .to_string(),
            ),
            task_list: String::new(),
            multi_select: false,
        }));
        app.spawn_confirmprompt();
        key(&mut app, KeyCode::Char('y'));
        let deadline = Instant::now() + Duration::from_secs(5);
        while !draw(&mut app, 200, 50).contains("loop started") {
            assert!(Instant::now() < deadline, "Fixture did not become ready");
            std::thread::sleep(Duration::from_millis(10));
        }

        let working_rendered = draw(&mut app, 200, 50);
        assert!(working_rendered.contains("Ctrl-C to cancel"));

        // Esc goes to the command: nothing stops and the window stays
        key(&mut app, KeyCode::Esc);
        assert!(matches!(app.focus, Focus::FloatingWindow(_)));
        assert!(draw(&mut app, 200, 50).contains("Running Command"));

        // Ctrl+C cancels the command without quitting linutil
        assert!(app.handle_key(&KeyEvent::new(KeyCode::Char('c'), KeyModifiers::CONTROL)));
        assert!(matches!(app.focus, Focus::FloatingWindow(_)));

        // and the window stays to show the result, until a key closes it
        let deadline = Instant::now() + Duration::from_secs(5);
        while !draw(&mut app, 200, 50).contains("Failed!") {
            assert!(Instant::now() < deadline, "Fixture did not stop");
            std::thread::sleep(Duration::from_millis(10));
        }
        std::thread::sleep(RESULT_KEY_PAUSE);
        key(&mut app, KeyCode::Esc);
        assert!(matches!(app.focus, Focus::List));
    }

    #[test]
    fn command_ending_without_new_output_asks_for_a_redraw() {
        use std::time::{Duration, Instant};
        let mut app = app();
        draw(&mut app, 200, 50);

        // The job left behind outlives the output, so the command ends in
        // silence, the way a command that prints nothing can.
        app.selected_commands.push(Rc::new(ListNode {
            name: "Silent fixture".to_string(),
            description: String::new(),
            command: Command::Raw("nohup sleep 1 >/dev/null 2>&1 &\nsleep 0.2".to_string()),
            task_list: String::new(),
            multi_select: false,
        }));
        app.spawn_confirmprompt();
        key(&mut app, KeyCode::Char('y'));
        assert!(draw(&mut app, 200, 50).contains("Running Command"));
        assert!(!app.needs_animation_frame());

        let deadline = Instant::now() + Duration::from_secs(5);
        while !app.needs_animation_frame() {
            assert!(
                Instant::now() < deadline,
                "No redraw after the command ended"
            );
            std::thread::sleep(Duration::from_millis(10));
        }
        assert!(draw(&mut app, 200, 50).contains("Done!"));
        assert!(!app.needs_animation_frame());
    }

    #[test]
    fn review_key_before_completion_draw_does_not_hide_result() {
        use std::time::{Duration, Instant};
        let mut app = app();
        draw(&mut app, 200, 50);
        app.selected_commands.push(Rc::new(ListNode {
            name: "Completion probe".to_string(),
            description: String::new(),
            command: Command::Raw("read -r release; exit 7".to_string()),
            task_list: String::new(),
            multi_select: false,
        }));
        app.spawn_confirmprompt();
        key(&mut app, KeyCode::Char('y'));
        assert!(draw(&mut app, 200, 50).contains("Running Command"));
        // The fixture ends only now, so the frame above is always a running one.
        key(&mut app, KeyCode::Enter);
        let deadline = Instant::now() + Duration::from_secs(5);
        while !matches!(&app.focus, Focus::FloatingWindow(float) if float.content.is_finished()) {
            assert!(Instant::now() < deadline);
            std::thread::sleep(Duration::from_millis(1));
        }
        assert!(
            app.needs_animation_frame(),
            "Completion should request a draw"
        );
        // main::run handles a ready key before drawing. The previous frame still
        // said Running Command, so this key must not discard the unseen failure.
        key(&mut app, KeyCode::Char('x'));
        assert!(
            matches!(app.focus, Focus::FloatingWindow(_)),
            "The queued key hid the result before any completion frame"
        );
        assert!(draw(&mut app, 200, 50).contains("Failed!"));
    }

    #[test]
    fn result_with_no_room_on_screen_waits_for_a_frame_before_closing() {
        use std::time::{Duration, Instant};
        let mut app = app();
        draw(&mut app, 200, 50);
        app.selected_commands.push(Rc::new(ListNode {
            name: "Completion probe".to_string(),
            description: String::new(),
            command: Command::Raw("exit 7".to_string()),
            task_list: String::new(),
            multi_select: false,
        }));
        app.spawn_confirmprompt();
        key(&mut app, KeyCode::Char('y'));
        let deadline = Instant::now() + Duration::from_secs(5);
        while !matches!(&app.focus, Focus::FloatingWindow(float) if float.content.is_finished()) {
            assert!(Instant::now() < deadline);
            std::thread::sleep(Duration::from_millis(1));
        }

        // The window is not drawn at all here, or only as a bare border.
        for (width, height) in [(3, 3), (5, 5)] {
            draw(&mut app, width, height);
            key(&mut app, KeyCode::Char('x'));
            assert!(matches!(app.focus, Focus::FloatingWindow(_)));
            assert!(app.needs_animation_frame());
        }

        // Once it has been drawn and keys have paused, the next one closes it.
        assert!(draw(&mut app, 200, 50).contains("Failed!"));
        assert!(!app.needs_animation_frame());
        std::thread::sleep(RESULT_KEY_PAUSE);
        key(&mut app, KeyCode::Char('x'));
        assert!(matches!(app.focus, Focus::List));
    }
}

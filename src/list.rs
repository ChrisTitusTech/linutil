use crate::{
    float::Float, preview_content::PreviewContent, running_command::Command, state::AppState,
};
use crossterm::event::{KeyCode, KeyEvent, KeyEventKind};
use ego_tree::{tree, NodeId};
use ratatui::{
    layout::Rect,
    style::{Style, Stylize},
    text::Line,
    widgets::{Block, Borders, List, ListState},
    Frame,
};

#[derive(Clone)]
struct ListNode {
    name: &'static str,
    command: Command,
}

/// This is a data structure that has everything necessary to draw and manage a menu of commands
pub struct CustomList {
    /// The tree data structure, to represent regular items
    /// and "directories"
    inner_tree: ego_tree::Tree<ListNode>,
    /// This stack keeps track of our "current dirrectory". You can think of it as `pwd`. but not
    /// just the current directory, all paths that took us here, so we can "cd .."
    visit_stack: Vec<NodeId>,
    /// This is the state asociated with the list widget, used to display the selection in the
    /// widget
    list_state: ListState,
    // This stores the current search query
    filter_query: String,
    // This stores the filtered tree
    filtered_items: Vec<ListNode>,
    // This is the preview window for the commands
    preview_float: Float<PreviewContent>,
}

impl CustomList {
    pub fn new() -> Self {
        // When a function call ends with an exclamation mark, it means it's a macro, like in this
        // case the tree! macro expands to `ego-tree::tree` data structure
        let tree = tree!(ListNode {
            name: "root",
            command: Command::None,
        } => {
            ListNode {
                name: "System Setup",
                command: Command::None,
            } => {
                ListNode {
                    name: "Build Prerequisites",
                    command: Command::LocalFile("system-setup/1-compile-setup.sh"),
                },
                ListNode {
                    name: "Gaming Dependencies",
                    command: Command::LocalFile("system-setup/2-gaming-setup.sh"),
                },
                ListNode {
                    name: "Global Theme",
                    command: Command::LocalFile("system-setup/3-global-theme.sh"),
                },
            },
            ListNode {
                name: "Security",
                command: Command::None
            } => {
                ListNode {
                    name: "Firewall Baselines (CTT)",
                    command: Command::LocalFile("security/firewall-baselines.sh"),
                }
            },
            ListNode {
                name: "Utilities",
                command: Command::None
            } => {
                ListNode {
                    name: "Wifi Manager",
                    command: Command::LocalFile("utils/wifi-control.sh"),
                },
                ListNode {
                    name: "Bluetooth Manager",
                    command: Command::LocalFile("utils/bluetooth-control.sh"),
                },
                ListNode {
                    name: "MonitorControl(xorg)",
                    command: Command::None,
                } => {
                    ListNode {
                        name: "Set Resolution",
                        command: Command::LocalFile("utils/monitor-control/set_resolutions.sh"),
                    },
                    ListNode {
                        name: "Duplicate Displays",
                        command: Command::LocalFile("utils/monitor-control/duplicate_displays.sh"),
                    },
                    ListNode {
                        name: "Extend Displays",
                        command: Command::LocalFile("utils/monitor-control/extend_displays.sh"),
                    },
                    ListNode {
                        name: "Auto Detect Displays",
                        command: Command::LocalFile("utils/monitor-control/auto_detect_displays.sh"),
                    },
                    ListNode {
                        name: "Enable Monitor",
                        command: Command::LocalFile("utils/monitor-control/enable_monitor.sh"),
                    },
                    ListNode {
                        name: "Disable Monitor",
                        command: Command::LocalFile("utils/monitor-control/disable_monitor.sh"),
                    },
                    ListNode {
                        name: "Set Primary Monitor",
                        command: Command::LocalFile("utils/monitor-control/set_primary_monitor.sh"),
                    },
                    ListNode {
                        name: "Change Orientation",
                        command: Command::LocalFile("utils/monitor-control/change_orientation.sh"),
                    },
                    ListNode {
                        name: "Manage Arrangement",
                        command: Command::LocalFile("utils/monitor-control/manage_arrangement.sh"),
                    },
                    ListNode {
                        name: "Scale Monitors",
                        command: Command::LocalFile("utils/monitor-control/scale_monitor.sh"),
                    },
                    ListNode {
                        name: "Reset Scaling",
                        command: Command::LocalFile("utils/monitor-control/reset_scaling.sh"),
                    },
                },
            },
            ListNode {
                name: "Applications Setup",
                command: Command::None
            } => {
                ListNode {
                    name: "Alacritty",
                    command: Command::LocalFile("applications-setup/alacritty-setup.sh"),
                },
                ListNode {
                    name: "Bash Prompt",
                    command: Command::Raw("bash -c \"$(curl -s https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/setup.sh)\""),
                },
                ListNode {
                    name: "DWM-Titus",
                    command: Command::LocalFile("applications-setup/dwmtitus-setup.sh")
                },
                ListNode {
                    name: "Kitty",
                    command: Command::LocalFile("applications-setup/kitty-setup.sh")
                },
                ListNode {
                    name: "Neovim",
                    command: Command::Raw("bash -c \"$(curl -s https://raw.githubusercontent.com/ChrisTitusTech/neovim/main/setup.sh)\""),
                },
                ListNode {
                    name: "Rofi",
                    command: Command::LocalFile("applications-setup/rofi-setup.sh"),
                },
                ListNode {
                    name: "ZSH Prompt",
                    command: Command::LocalFile("applications-setup/zsh-setup.sh"),
                }

            },
            ListNode {
                name: "Full System Update",
                command: Command::LocalFile("system-update.sh"),
            },
        });
        // We don't get a reference, but rather an id, because references are siginficantly more
        // paintfull to manage
        let root_id = tree.root().id();
        Self {
            inner_tree: tree,
            visit_stack: vec![root_id],
            list_state: ListState::default().with_selected(Some(0)),
            filter_query: String::new(),
            filtered_items: vec![],
            preview_float: Float::new(80, 80),
        }
    }

    /// Draw our custom widget to the frame
    pub fn draw(&mut self, frame: &mut Frame, area: Rect, state: &AppState) {
        let item_list: Vec<Line> = if self.filter_query.is_empty() {
            let mut items: Vec<Line> = vec![];
            // If we are not at the root of our filesystem tree, we need to add `..` path, to be able
            // to go up the tree
            // icons:   
            if !self.at_root() {
                items.push(
                    Line::from(format!("{}  ..", state.theme.dir_icon))
                        .style(state.theme.dir_color),
                );
            }

            // Get the last element in the `visit_stack` vec
            let curr = self
                .inner_tree
                .get(*self.visit_stack.last().unwrap())
                .unwrap();

            // Iterate through all the children
            for node in curr.children() {
                // The difference between a "directory" and a "command" is simple: if it has children,
                // it's a directory and will be handled as such
                if node.has_children() {
                    items.push(
                        Line::from(format!("{}  {}", state.theme.dir_icon, node.value().name))
                            .style(state.theme.dir_color),
                    );
                } else {
                    items.push(
                        Line::from(format!("{}  {}", state.theme.cmd_icon, node.value().name))
                            .style(state.theme.cmd_color),
                    );
                }
            }
            items
        } else {
            self.filtered_items
                .iter()
                .map(|node| {
                    Line::from(format!("{}  {}", state.theme.cmd_icon, node.name))
                        .style(state.theme.cmd_color)
                })
                .collect()
        };

        // create the normal list widget containing only item in our "working directory" / tree
        // node
        let list = List::new(item_list)
            .highlight_style(Style::default().reversed())
            .block(Block::default().borders(Borders::ALL).title(format!(
                "Linux Toolbox - {}",
                chrono::Local::now().format("%Y-%m-%d")
            )))
            .scroll_padding(1);

        // Render it
        frame.render_stateful_widget(list, area, &mut self.list_state);

        //Render the preview window
        self.preview_float.draw(frame, area);
    }

    pub fn filter(&mut self, query: String) {
        self.filter_query.clone_from(&query);
        self.filtered_items.clear();

        let query_lower = query.to_lowercase();

        let mut stack = vec![self.inner_tree.root().id()];

        while let Some(node_id) = stack.pop() {
            let node = self.inner_tree.get(node_id).unwrap();

            if node.value().name.to_lowercase().contains(&query_lower) && !node.has_children() {
                self.filtered_items.push(node.value().clone());
            }

            for child in node.children() {
                stack.push(child.id());
            }
        }
        self.filtered_items.sort_by(|a, b| a.name.cmp(b.name));
    }

    /// Resets the selection to the first item
    pub fn reset_selection(&mut self) {
        if !self.filtered_items.is_empty() {
            self.list_state.select(Some(0));
        } else {
            self.list_state.select(None);
        }
    }

    /// Handle key events, we are only interested in `Press` and `Repeat` events
    pub fn handle_key(&mut self, event: KeyEvent, state: &AppState) -> Option<Command> {
        if event.kind == KeyEventKind::Release {
            return None;
        }

        if self.preview_float.handle_key_event(&event) {
            return None; // If the key event was handled by the preview, don't propagate it further
        }

        match event.code {
            // Damm you Up arrow, use vim lol
            KeyCode::Char('j') | KeyCode::Down => {
                self.list_state.select_next();
                None
            }
            KeyCode::Char('k') | KeyCode::Up => {
                self.list_state.select_previous();
                None
            }
            KeyCode::Char('p') => {
                self.toggle_preview_window(state);
                None
            }
            KeyCode::Enter => self.handle_enter(),
            _ => None,
        }
    }

    fn get_selected_command(&self) -> Option<Command> {
        let selected_index = self.list_state.selected().unwrap_or(0);

        if self.filter_query.is_empty() {
            // No filter query, use the regular tree navigation
            let curr = self
                .inner_tree
                .get(*self.visit_stack.last().unwrap())
                .unwrap();

            if !self.at_root() && selected_index == 0 {
                return None;
            }

            let mut actual_index = selected_index;
            if !self.at_root() {
                actual_index -= 1; // Adjust for the ".." item if not at root
            }

            for (idx, node) in curr.children().enumerate() {
                if idx == actual_index {
                    return Some(node.value().command.clone());
                }
            }
        } else {
            // Filter query is active, use the filtered items
            if let Some(filtered_node) = self.filtered_items.get(selected_index) {
                return Some(filtered_node.command.clone());
            }
        }

        None
    }

    /// Handles the <Enter> key. This key can do 3 things:
    /// - Run a command, if it is the currently selected item,
    /// - Go up a directory
    /// - Go down into a directory
    ///
    /// Returns `Some(command)` when command is selected, othervise we returns `None`
    fn handle_enter(&mut self) -> Option<Command> {
        let selected_index = self.list_state.selected().unwrap_or(0);

        if self.filter_query.is_empty() {
            // No filter query, use the regular tree navigation
            let curr = self
                .inner_tree
                .get(*self.visit_stack.last().unwrap())
                .unwrap();

            if !self.at_root() && selected_index == 0 {
                self.visit_stack.pop();
                self.list_state.select(Some(0));
                return None;
            }

            let mut actual_index = selected_index;
            if !self.at_root() {
                actual_index -= 1; // Adjust for the ".." item if not at root
            }

            for (idx, node) in curr.children().enumerate() {
                if idx == actual_index {
                    if node.has_children() {
                        self.visit_stack.push(node.id());
                        self.list_state.select(Some(0));
                        return None;
                    } else {
                        return Some(node.value().command.clone());
                    }
                }
            }
        } else {
            // Filter query is active, use the filtered items
            if let Some(filtered_node) = self.filtered_items.get(selected_index) {
                return Some(filtered_node.command.clone());
            }
        }

        None
    }

    fn toggle_preview_window(&mut self, state: &AppState) {
        if self.preview_float.get_content().is_some() {
            // If the preview window is active, disable it
            self.preview_float.set_content(None);
        } else {
            // If the preview window is not active, show it

            // Get the selected command
            if let Some(selected_command) = self.get_selected_command() {
                let lines = match selected_command {
                    Command::Raw(cmd) => cmd.lines().map(|line| line.to_string()).collect(),
                    Command::LocalFile(file_path) => {
                        if file_path.is_empty() {
                            return;
                        }
                        let mut full_path = state.temp_path.clone();
                        full_path.push(file_path);
                        let file_contents = std::fs::read_to_string(&full_path)
                            .map_err(|_| format!("File not found: {:?}", &full_path))
                            .unwrap();
                        file_contents.lines().map(|line| line.to_string()).collect()
                    }
                    Command::None => return,
                };

                self.preview_float
                    .set_content(Some(PreviewContent::new(lines)));
            }
        }
    }

    /// Checks weather the current tree node is the root node (can we go up the tree or no)
    /// Returns `true` if we can't go up the tree (we are at the tree root)
    /// else returns `false`
    fn at_root(&self) -> bool {
        self.visit_stack.len() == 1
    }
}

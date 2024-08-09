use std::sync::LazyLock;

use ego_tree::{tree, Tree};

use crate::running_command::Command;

pub struct Tab {
    pub name: &'static str,
    pub tree: Tree<ListNode>,
}

#[derive(Clone)]
pub struct ListNode {
    pub name: &'static str,
    pub command: Command,
}

pub static TABS: LazyLock<Vec<Tab>> = LazyLock::new(|| {
    vec![
        Tab {
            name: "System Setup",
            tree: tree!(ListNode {
                name: "root",
                command: Command::None,
            } => {
                ListNode {
                    name: "Full System Update",
                    command: Command::LocalFile("system-update.sh"),
                },
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
                ListNode {
                    name: "Remove Snaps",
                    command: Command::LocalFile("system-setup/4-remove-snaps.sh"),
                }
            }),
        },
        Tab {
            name: "Applications Setup",
            tree: tree!(ListNode {
                name: "root",
                command: Command::None,
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
            }),
        },
        Tab {
            name: "Security",
            tree: tree!(ListNode {
                name: "root",
                command: Command::None,
            } => {
                ListNode {
                    name: "Firewall Baselines (CTT)",
                    command: Command::LocalFile("security/firewall-baselines.sh"),
                }
            }),
        },
        Tab {
            name: "Utilities",
            tree: tree!(ListNode {
                name: "root",
                command: Command::None,
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
                    }
                },
            }),
        },
    ]
});

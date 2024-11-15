use crate::{ListNode, TabList};
use serde::Deserialize;
use std::{fs, path::Path, process, rc::Rc};

// Struct that defines what values can be used in the toml file
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Config {
    #[serde(default)]
    auto_execute: Option<Vec<String>>,
    #[serde(default)]
    skip_confirmation: Option<bool>,
    #[serde(default)]
    size_bypass: Option<bool>,
}

// Struct that holds the parsed values from the toml so that it can be applied in the AppState
pub struct ConfigValues {
    pub auto_execute_commands: Vec<Rc<ListNode>>,
    pub skip_confirmation: bool,
    pub size_bypass: bool,
}

impl Config {
    pub fn read_config(path: &Path, tabs: &TabList) -> ConfigValues {
        let content = match fs::read_to_string(path) {
            Ok(content) => content,
            Err(e) => {
                eprintln!("Failed to read config file {}: {}", path.display(), e);
                process::exit(1);
            }
        };

        let config: Config = match toml::from_str(&content) {
            Ok(config) => config,
            Err(e) => {
                eprintln!("Failed to parse config file: {}", e);
                process::exit(1);
            }
        };

        ConfigValues {
            auto_execute_commands: config.auto_execute_commands(tabs),
            skip_confirmation: config.skip_confirmation.unwrap_or(false),
            size_bypass: config.size_bypass.unwrap_or(false),
        }
    }

    fn auto_execute_commands(&self, tabs: &TabList) -> Vec<Rc<ListNode>> {
        self.auto_execute
            .as_ref()
            .map_or_else(Vec::new, |commands| {
                commands
                    .iter()
                    .filter_map(|name| tabs.iter().find_map(|tab| tab.find_command_by_name(name)))
                    .collect()
            })
    }
}

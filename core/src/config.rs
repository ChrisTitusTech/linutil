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
                eprintln!("Failed to parse config file: {e}");
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_read_config() {
        let temp_dir = crate::tests::create_temp_dir();
        let config_path = temp_dir.path().join("config.toml");

        fs::write(
            &config_path,
            r#"auto_execute = ["command1", "nonexistent"]
            skip_confirmation = true
            size_bypass = false"#,
        )
        .unwrap();

        let tab_list = crate::tests::create_tab_list();
        let config = Config::read_config(&config_path, &tab_list);

        assert_eq!(config.auto_execute_commands.len(), 1);
        assert_eq!(config.skip_confirmation, true);
        assert_eq!(config.size_bypass, false);

        drop(temp_dir);
    }

    #[test]
    fn test_auto_execute_commands() {
        let tab_list = crate::tests::create_tab_list();

        let config = Config {
            auto_execute: Some(vec!["command1".to_string(), "nonexistent".to_string()]),
            skip_confirmation: Some(true),
            size_bypass: Some(false),
        };

        let auto_execute_commands = config.auto_execute_commands(&tab_list);

        assert_eq!(auto_execute_commands.len(), 1);
        assert_eq!(auto_execute_commands[0].name, "command1");
    }
}

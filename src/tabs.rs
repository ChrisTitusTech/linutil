use crate::running_command::Command;
use ego_tree::{NodeMut, Tree};
use serde::Deserialize;
use std::path::{Path, PathBuf};

#[derive(Deserialize)]
struct TabList {
    directories: Vec<PathBuf>,
}

#[derive(Deserialize)]
struct TabEntry {
    name: String,
    data: Vec<Entry>,
}

#[derive(Deserialize)]
struct Entry {
    name: String,
    #[allow(dead_code)]
    #[serde(default)]
    description: String,
    #[serde(default)]
    preconditions: Option<Vec<Precondition>>,
    #[serde(default)]
    entries: Option<Vec<Entry>>,
    #[serde(default)]
    command: Option<String>,
    #[serde(default)]
    script: Option<PathBuf>,
}

impl Entry {
    fn is_supported(&self) -> bool {
        self.preconditions.as_deref().map_or(true, |preconditions| {
            preconditions.iter().all(
                |Precondition {
                     matches,
                     data,
                     values,
                 }| {
                    match data {
                        SystemDataType::Environment(var_name) => std::env::var(var_name)
                            .map_or(false, |var| values.contains(&var) == *matches),
                        SystemDataType::File(path) => {
                            std::fs::read_to_string(path).map_or(false, |data| {
                                values
                                    .iter()
                                    .any(|matching_value| data.contains(matching_value))
                                    == *matches
                            })
                        }
                        SystemDataType::CommandExists => values
                            .iter()
                            .all(|command| which::which(command).is_ok() == *matches),
                    }
                },
            )
        })
    }
}

#[derive(Deserialize)]
struct Precondition {
    // If true, the data must be contained within the list of values.
    // Otherwise, the data must not be contained within the list of values
    matches: bool,
    data: SystemDataType,
    values: Vec<String>,
}

#[derive(Deserialize)]
enum SystemDataType {
    #[serde(rename = "environment")]
    Environment(String),
    #[serde(rename = "file")]
    File(PathBuf),
    #[serde(rename = "command_exists")]
    CommandExists,
}

#[derive(Hash, Eq, PartialEq)]
pub struct Tab {
    pub name: String,
    pub tree: Tree<ListNode>,
}

#[derive(Clone, Hash, Eq, PartialEq)]
pub struct ListNode {
    pub name: String,
    pub command: Command,
}

pub fn get_tabs(command_dir: &Path, validate: bool) -> Vec<Tab> {
    let tab_files = TabList::get_tabs(command_dir);
    let tabs = tab_files.into_iter().map(|path| {
        let directory = path.parent().unwrap().to_owned();
        let data = std::fs::read_to_string(path).expect("Failed to read tab data");
        let mut tab_data: TabEntry = toml::from_str(&data).expect("Failed to parse tab data");

        if validate {
            filter_entries(&mut tab_data.data);
        }
        (tab_data, directory)
    });

    let tabs: Vec<Tab> = tabs
        .map(|(TabEntry { name, data }, directory)| {
            let mut tree = Tree::new(ListNode {
                name: "root".to_string(),
                command: Command::None,
            });
            let mut root = tree.root_mut();
            create_directory(data, &mut root, &directory);
            Tab { name, tree }
        })
        .collect();

    if tabs.is_empty() {
        panic!("No tabs found");
    }
    tabs
}

fn filter_entries(entries: &mut Vec<Entry>) {
    entries.retain_mut(|entry| {
        if !entry.is_supported() {
            return false;
        }
        if let Some(entries) = &mut entry.entries {
            filter_entries(entries);
            !entries.is_empty()
        } else {
            true
        }
    });
}

fn create_directory(data: Vec<Entry>, node: &mut NodeMut<ListNode>, command_dir: &Path) {
    for entry in data {
        if [
            entry.entries.is_some(),
            entry.command.is_some(),
            entry.script.is_some(),
        ]
        .iter()
        .filter(|&&x| x)
        .count()
            > 1
        {
            panic!("Entry must have only one data type");
        }

        if let Some(entries) = entry.entries {
            let mut node = node.append(ListNode {
                name: entry.name,
                command: Command::None,
            });
            create_directory(entries, &mut node, command_dir);
        } else if let Some(command) = entry.command {
            node.append(ListNode {
                name: entry.name,
                command: Command::Raw(command),
            });
        } else if let Some(script) = entry.script {
            let dir = command_dir.join(script);
            if !dir.exists() {
                panic!("Script {} does not exist", dir.display());
            }
            node.append(ListNode {
                name: entry.name,
                command: Command::LocalFile(dir),
            });
        } else {
            panic!("Entry must have data");
        }
    }
}
impl TabList {
    fn get_tabs(command_dir: &Path) -> Vec<PathBuf> {
        let tab_files = std::fs::read_to_string(command_dir.join("tabs.toml"))
            .expect("Failed to read tabs.toml");
        let data: Self = toml::from_str(&tab_files).expect("Failed to parse tabs.toml");

        data.directories
            .into_iter()
            .map(|path| command_dir.join(path).join("tab_data.toml"))
            .collect()
    }
}

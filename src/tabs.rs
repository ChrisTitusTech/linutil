use crate::running_command::Command;
use ego_tree::{NodeMut, Tree};
use serde::Deserialize;
use std::path::{Path, PathBuf};

#[derive(Deserialize)]
struct TabEntry {
    name: String,
    data: Vec<Entry>,
}

#[derive(Deserialize)]
enum Entry {
    #[serde(rename = "directory")]
    Directory(EntryData<Vec<Entry>>),
    #[serde(rename = "command")]
    Command(EntryData<String>),
    #[serde(rename = "script")]
    Script(EntryData<PathBuf>),
}

#[derive(Deserialize)]
struct EntryData<T> {
    name: String,
    #[allow(dead_code)]
    #[serde(default)]
    description: String,
    data: T,
    #[serde(default)]
    preconditions: Option<Vec<Precondition>>,
}

impl<T> EntryData<T> {
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
    let tab_files =
        std::fs::read_to_string(command_dir.join("tabs.json")).expect("Failed to read tabs.json");
    let tab_files: Vec<PathBuf> =
        serde_json::from_str(&tab_files).expect("Failed to parse tabs.json");
    let tabs = tab_files.into_iter().map(|path| {
        let file = command_dir.join(&path);
        let directory = file.parent().unwrap().to_owned();
        let data =
            std::fs::read_to_string(command_dir.join(path)).expect("Failed to read tab data");
        let mut tab_data: TabEntry = serde_json::from_str(&data).expect("Failed to parse tab data");

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
    entries.retain_mut(|entry| match entry {
        Entry::Script(entry) => entry.is_supported(),
        Entry::Command(entry) => entry.is_supported(),
        Entry::Directory(entry) if !entry.is_supported() => false,
        Entry::Directory(entry) => {
            filter_entries(&mut entry.data);
            !entry.data.is_empty()
        }
    });
}

fn create_directory(data: Vec<Entry>, node: &mut NodeMut<ListNode>, command_dir: &Path) {
    for entry in data {
        match entry {
            Entry::Directory(entry) => {
                let mut node = node.append(ListNode {
                    name: entry.name,
                    command: Command::None,
                });
                create_directory(entry.data, &mut node, command_dir);
            }
            Entry::Command(entry) => {
                node.append(ListNode {
                    name: entry.name,
                    command: Command::Raw(entry.data),
                });
            }
            Entry::Script(entry) => {
                let dir = command_dir.join(entry.data);
                if !dir.exists() {
                    panic!("Script {} does not exist", dir.display());
                }
                node.append(ListNode {
                    name: entry.name,
                    command: Command::LocalFile(dir),
                });
            }
        }
    }
}

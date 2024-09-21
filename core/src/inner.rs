use crate::{Command, ListNode, Tab};
use ego_tree::{NodeMut, Tree};
use include_dir::{include_dir, Dir};
use serde::Deserialize;
use std::{
    fs::File,
    io::{BufRead, BufReader, Read},
    path::{Path, PathBuf},
};
use tempdir::TempDir;

const TAB_DATA: Dir = include_dir!("$CARGO_MANIFEST_DIR/tabs");

pub fn get_tabs(validate: bool) -> Vec<Tab> {
    let tab_files = TabList::get_tabs();
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
        .map(
            |(
                TabEntry {
                    name,
                    data,
                    multi_selectable,
                },
                directory,
            )| {
                let mut tree = Tree::new(ListNode {
                    name: "root".to_string(),
                    description: String::new(),
                    command: Command::None,
                });
                let mut root = tree.root_mut();
                create_directory(data, &mut root, &directory);
                Tab {
                    name,
                    tree,
                    multi_selectable,
                }
            },
        )
        .collect();

    if tabs.is_empty() {
        panic!("No tabs found");
    }
    tabs
}

#[derive(Deserialize)]
struct TabList {
    directories: Vec<PathBuf>,
}

#[derive(Deserialize)]
struct TabEntry {
    name: String,
    data: Vec<Entry>,
    #[serde(default = "default_multi_selectable")]
    multi_selectable: bool,
}

fn default_multi_selectable() -> bool {
    true
}

#[derive(Deserialize)]
struct Entry {
    name: String,
    #[allow(dead_code)]
    #[serde(default)]
    description: String,
    #[serde(default)]
    preconditions: Option<Vec<Precondition>>,
    #[serde(flatten)]
    entry_type: EntryType,
}

#[derive(Deserialize)]
enum EntryType {
    #[serde(rename = "entries")]
    Entries(Vec<Entry>),
    #[serde(rename = "command")]
    Command(String),
    #[serde(rename = "script")]
    Script(PathBuf),
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

fn filter_entries(entries: &mut Vec<Entry>) {
    entries.retain_mut(|entry| {
        if !entry.is_supported() {
            return false;
        }
        if let EntryType::Entries(entries) = &mut entry.entry_type {
            filter_entries(entries);
            !entries.is_empty()
        } else {
            true
        }
    });
}

fn create_directory(data: Vec<Entry>, node: &mut NodeMut<ListNode>, command_dir: &Path) {
    for entry in data {
        match entry.entry_type {
            EntryType::Entries(entries) => {
                let mut node = node.append(ListNode {
                    name: entry.name,
                    description: entry.description,
                    command: Command::None,
                });
                create_directory(entries, &mut node, command_dir);
            }
            EntryType::Command(command) => {
                node.append(ListNode {
                    name: entry.name,
                    description: entry.description,
                    command: Command::Raw(command),
                });
            }
            EntryType::Script(script) => {
                let script = command_dir.join(script);
                if !script.exists() {
                    panic!("Script {} does not exist", script.display());
                }

                let (executable, mut args) = get_shebang(&script);
                args.push(script.to_string_lossy().to_string());

                node.append(ListNode {
                    name: entry.name,
                    description: entry.description,
                    command: Command::LocalFile {
                        executable,
                        args,
                        file: script,
                    },
                });
            }
        }
    }
}

fn get_shebang(script: &Path) -> (String, Vec<String>) {
    let default_executable = || ("sh".into(), vec!["-e".into()]);

    let script = File::open(script).expect("Failed to open script file");
    let mut reader = BufReader::new(script);

    // Take the first 2 characters from the reader; check whether it's a shebang
    let mut two_chars = [0; 2];
    if reader.read_exact(&mut two_chars).is_err() || two_chars != *b"#!" {
        return default_executable();
    }

    let first_line = reader.lines().next().unwrap().unwrap();

    let mut parts = first_line.split_whitespace();

    let executable = parts.next().unwrap_or("sh").to_string();
    let args = parts.map(ToString::to_string).collect();

    (executable, args)
}

impl TabList {
    fn get_tabs() -> Vec<PathBuf> {
        let temp_dir = TempDir::new("linutil_scripts").unwrap().into_path();
        TAB_DATA
            .extract(&temp_dir)
            .expect("Failed to extract the saved directory");

        let tab_files =
            std::fs::read_to_string(temp_dir.join("tabs.toml")).expect("Failed to read tabs.toml");
        let data: Self = toml::from_str(&tab_files).expect("Failed to parse tabs.toml");

        data.directories
            .iter()
            .map(|path| temp_dir.join(path).join("tab_data.toml"))
            .collect()
    }
}

use crate::{Command, ListNode, Tab};
use ego_tree::{NodeMut, Tree};
use include_dir::{include_dir, Dir};
use serde::{Deserialize, Serialize};
use std::{
    collections::HashSet,
    path::{Path, PathBuf},
    sync::LazyLock,
};
use tempdir::TempDir;

static STORE_FILE: LazyLock<PathBuf> = LazyLock::new(|| {
    let state_dir = dirs::state_dir().expect("Failed to get state directory");
    let store_file_path = state_dir.join("linutil_scripts.toml");
    if !store_file_path.exists() {
        std::fs::File::create(&store_file_path).expect("Failed to create store file");
    }
    store_file_path
});

const TAB_DATA: Dir = include_dir!("$CARGO_MANIFEST_DIR/../tabs");

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

    let contents =
        std::fs::read_to_string(STORE_FILE.as_path()).expect("Failed to read store file");
    let completed_scripts: CompletedScripts = toml::from_str(&contents).unwrap_or_default();

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
                    command: Command::None,
                    revertable: false,
                    default_revertable: false,
                });
                let mut root = tree.root_mut();
                create_directory(data, &mut root, &directory, &completed_scripts.scripts);
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
    revertable: Option<bool>,
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

fn create_directory(
    data: Vec<Entry>,
    node: &mut NodeMut<ListNode>,
    command_dir: &Path,
    run_scripts: &HashSet<String>,
) {
    for entry in data {
        match entry.entry_type {
            EntryType::Entries(entries) => {
                let mut node = node.append(ListNode {
                    name: entry.name,
                    command: Command::None,
                    revertable: false,
                    default_revertable: false,
                });
                create_directory(entries, &mut node, command_dir, run_scripts);
            }
            EntryType::Command(command) => {
                node.append(ListNode {
                    name: entry.name,
                    command: Command::Raw(command),
                    revertable: false,
                    default_revertable: false,
                });
            }
            EntryType::Script(script) => {
                let dir = command_dir.join(&script);
                if !dir.exists() {
                    panic!("Script {} does not exist", dir.display());
                }
                let script_name = script
                    .components()
                    .last()
                    .unwrap()
                    .as_os_str()
                    .to_string_lossy();
                node.append(ListNode {
                    name: entry.name,
                    command: Command::LocalFile(dir),
                    revertable: entry.revertable.unwrap_or(true),
                    default_revertable: run_scripts.contains(script_name.as_ref()),
                });
            }
        }
    }
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

#[derive(Default, Deserialize, Serialize)]
struct CompletedScripts {
    scripts: HashSet<String>,
}

pub fn write_script_inner(script_path: &Path, revert: bool) {
    let contents =
        std::fs::read_to_string(STORE_FILE.as_path()).expect("Failed to read store file");
    let mut completed_scripts: CompletedScripts = toml::from_str(&contents).unwrap_or_default();

    // Take only the filename of the script
    let script_path = script_path.components().last().unwrap().as_os_str();
    if revert {
        completed_scripts
            .scripts
            .remove(script_path.to_string_lossy().as_ref());
    } else {
        completed_scripts
            .scripts
            .insert(script_path.to_string_lossy().to_string());
    }
    std::fs::write(
        STORE_FILE.as_path(),
        toml::to_string_pretty(&completed_scripts).expect("Failed to serialize completed scripts"),
    )
    .expect("Failed to write store file");
}

use std::{
    fs::File,
    io::{BufRead, BufReader, Read},
    ops::{Deref, DerefMut},
    os::unix::fs::PermissionsExt,
    path::{Path, PathBuf},
    rc::Rc,
};

use crate::{Command, ListNode, Tab};
use ego_tree::{NodeMut, Tree};
use include_dir::{include_dir, Dir};
use serde::Deserialize;
use temp_dir::TempDir;

const TAB_DATA: Dir = include_dir!("$CARGO_MANIFEST_DIR/tabs");

// Allow the unused TempDir to be stored for later destructor call
#[allow(dead_code)]
pub struct TabList(pub Vec<Tab>, TempDir);

// Implement deref to allow Vec<Tab> methods to be called on TabList
impl Deref for TabList {
    type Target = Vec<Tab>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
impl DerefMut for TabList {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}
impl IntoIterator for TabList {
    type Item = Tab;
    type IntoIter = std::vec::IntoIter<Self::Item>;

    fn into_iter(self) -> Self::IntoIter {
        self.0.into_iter()
    }
}

pub fn get_tabs(validate: bool) -> TabList {
    let (temp_dir, tab_files) = TabDirectories::get_tabs();

    let tabs: Vec<_> = tab_files
        .into_iter()
        .map(|path| {
            let directory = path.parent().unwrap().to_owned();
            let data = std::fs::read_to_string(path).expect("Failed to read tab data");
            let mut tab_data: TabEntry = toml::from_str(&data).expect("Failed to parse tab data");

            if validate {
                filter_entries(&mut tab_data.data);
            }
            (tab_data, directory)
        })
        .collect();

    let tabs: Vec<Tab> = tabs
        .into_iter()
        .map(|(TabEntry { name, data }, directory)| {
            let mut tree = Tree::new(Rc::new(ListNode {
                name: "root".to_string(),
                description: String::new(),
                command: Command::None,
                task_list: String::new(),
                multi_select: false,
            }));
            let mut root = tree.root_mut();
            create_directory(data, &mut root, &directory, validate, true);
            Tab { name, tree }
        })
        .collect();

    if tabs.is_empty() {
        panic!("No tabs found");
    }
    TabList(tabs, temp_dir)
}

#[derive(Deserialize)]
struct TabDirectories {
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
    #[serde(flatten)]
    entry_type: EntryType,
    #[serde(default)]
    task_list: String,
    #[serde(default = "default_true")]
    multi_select: bool,
}

fn default_true() -> bool {
    true
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
    node: &mut NodeMut<Rc<ListNode>>,
    command_dir: &Path,
    validate: bool,
    parent_multi_select: bool,
) {
    for entry in data {
        let multi_select = parent_multi_select && entry.multi_select;

        match entry.entry_type {
            EntryType::Entries(entries) => {
                let mut node = node.append(Rc::new(ListNode {
                    name: entry.name,
                    description: entry.description,
                    command: Command::None,
                    task_list: String::new(),
                    multi_select,
                }));
                create_directory(entries, &mut node, command_dir, validate, multi_select);
            }
            EntryType::Command(command) => {
                node.append(Rc::new(ListNode {
                    name: entry.name,
                    description: entry.description,
                    command: Command::Raw(command),
                    task_list: String::new(),
                    multi_select,
                }));
            }
            EntryType::Script(script) => {
                let script = command_dir.join(script);
                if !script.exists() {
                    panic!("Script {} does not exist", script.display());
                }

                if let Some((executable, args)) = get_shebang(&script, validate) {
                    node.append(Rc::new(ListNode {
                        name: entry.name,
                        description: entry.description,
                        command: Command::LocalFile {
                            executable,
                            args,
                            file: script,
                        },
                        task_list: entry.task_list,
                        multi_select,
                    }));
                }
            }
        }
    }
}

fn get_shebang(script_path: &Path, validate: bool) -> Option<(String, Vec<String>)> {
    let default_executable = || Some(("/bin/sh".into(), vec!["-e".into()]));

    let script = File::open(script_path).expect("Failed to open script file");
    let mut reader = BufReader::new(script);

    // Take the first 2 characters from the reader; check whether it's a shebang
    let mut two_chars = [0; 2];
    if reader.read_exact(&mut two_chars).is_err() || two_chars != *b"#!" {
        return default_executable();
    }

    let first_line = reader.lines().next().unwrap().unwrap();

    let mut parts = first_line.split_whitespace();

    let Some(executable) = parts.next() else {
        return default_executable();
    };

    let is_valid = !validate || is_executable(Path::new(executable));

    is_valid.then(|| {
        let mut args: Vec<String> = parts.map(ToString::to_string).collect();
        args.push(script_path.to_string_lossy().to_string());
        (executable.to_string(), args)
    })
}

fn is_executable(path: &Path) -> bool {
    path.metadata()
        .map(|metadata| metadata.is_file() && metadata.permissions().mode() & 0o111 != 0)
        .unwrap_or(false)
}

impl TabDirectories {
    fn get_tabs() -> (TempDir, Vec<PathBuf>) {
        let temp_dir = TempDir::with_prefix("linutil_scripts").unwrap();
        TAB_DATA
            .extract(&temp_dir)
            .expect("Failed to extract the saved directory");

        let tab_files = std::fs::read_to_string(temp_dir.path().join("tabs.toml"))
            .expect("Failed to read tabs.toml");
        let data: Self = toml::from_str(&tab_files).expect("Failed to parse tabs.toml");
        let tab_paths = data
            .directories
            .iter()
            .map(|path| temp_dir.path().join(path).join("tab_data.toml"))
            .collect();
        (temp_dir, tab_paths)
    }
}

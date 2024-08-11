use crate::running_command::Command;
use ego_tree::{tree, NodeId, Tree};
use serde::Deserialize;
use std::{
    collections::{HashMap, HashSet},
    path::{Path, PathBuf},
    sync::LazyLock,
};

#[derive(Deserialize)]
struct ScriptInfo {
    ui_path: Vec<String>,
    #[serde(default)]
    description: String,
    #[serde(default)]
    preconditions: Option<Vec<Precondition>>,
    #[serde(default)]
    command: Option<String>,
}

impl ScriptInfo {
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
    let scripts = get_script_list(command_dir);

    let mut paths: HashMap<Vec<String>, (String, NodeId)> = HashMap::new();
    let mut tabs: Vec<Tab> = Vec::new();

    for (json_file, script) in scripts {
        let json_text = std::fs::read_to_string(&json_file).unwrap();
        let script_info: ScriptInfo =
            serde_json::from_str(&json_text).expect("Unexpected JSON input");
        if validate && !script_info.is_supported() {
            continue;
        }
        if script_info.ui_path.len() < 2 {
            panic!(
                "UI path must contain a tab. Ensure that {} has correct data",
                json_file.display()
            );
        }
        let command = match script_info.command {
            Some(command) => Command::Raw(command),
            None if script.exists() => Command::LocalFile(script),
            _ => panic!(
                "Command not specified & matching script does not exist for JSON {}",
                json_file.display()
            ),
        };
        for path_index in 1..script_info.ui_path.len() {
            let path = script_info.ui_path[..path_index].to_vec();
            if !paths.contains_key(&path) {
                let tab_name = script_info.ui_path[0].clone();
                if path_index == 1 {
                    let tab = Tab {
                        name: tab_name.clone(),
                        tree: Tree::new(ListNode {
                            name: "root".to_string(),
                            command: Command::None,
                        }),
                    };
                    let root_id = tab.tree.root().id();
                    tabs.push(tab);
                    paths.insert(path, (tab_name, root_id));
                } else {
                    let parent_path = &script_info.ui_path[..path_index - 1];
                    let (tab, parent_id) = paths.get(parent_path).unwrap();
                    let tab = tabs
                        .iter_mut()
                        .find(|Tab { name, .. }| name == tab)
                        .unwrap();
                    let mut parent = tab.tree.get_mut(*parent_id).unwrap();
                    let new_node = ListNode {
                        name: script_info.ui_path[path_index - 1].clone(),
                        command: Command::None,
                    };
                    let new_id = parent.append(new_node).id();
                    paths.insert(path, (tab_name, new_id));
                }
            }
        }
        let (tab, parent_id) = paths
            .get(&script_info.ui_path[..script_info.ui_path.len() - 1])
            .unwrap();
        let tab = tabs
            .iter_mut()
            .find(|Tab { name, .. }| name == tab)
            .unwrap();
        let mut parent = tab.tree.get_mut(*parent_id).unwrap();

        let command = ListNode {
            name: script_info.ui_path.last().unwrap().clone(),
            command,
        };
        parent.append(command);
    }
    if tabs.is_empty() {
        panic!("No tabs found.");
    }
    tabs
}

fn get_script_list(directory: &Path) -> Vec<(PathBuf, PathBuf)> {
    let mut entries = std::fs::read_dir(directory)
        .expect("Command directory does not exist.")
        .flatten()
        .collect::<Vec<_>>();
    entries.sort_by_key(|d| d.path());

    entries
        .into_iter()
        .filter_map(|entry| {
            let path = entry.path();
            // Recursively iterate through directories
            if entry.file_type().map_or(false, |f| f.is_dir()) {
                Some(get_script_list(&path))
            } else {
                let is_json = path.extension().map_or(false, |ext| ext == "json");
                let script = path.with_extension("sh");
                (is_json).then_some(vec![(path, script)])
            }
        })
        .flatten()
        .collect()
}

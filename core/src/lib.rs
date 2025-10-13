mod config;
mod inner;

use std::rc::Rc;

pub use ego_tree;
use ego_tree::Tree;
use std::path::PathBuf;

pub use config::{Config, ConfigValues};
pub use inner::{get_tabs, TabList};

#[derive(Clone, Hash, Eq, PartialEq)]
pub enum Command {
    Raw(String),
    LocalFile {
        executable: String,
        args: Vec<String>,
        // The file path is included within the arguments; don't pass this in addition
        file: PathBuf,
    },
    None, // Directory
}

#[derive(Clone, Hash, Eq, PartialEq)]
pub struct Tab {
    pub name: String,
    pub tree: Tree<Rc<ListNode>>,
}

#[derive(Clone, Hash, Eq, PartialEq)]
pub struct ListNode {
    pub name: String,
    pub description: String,
    pub command: Command,
    pub task_list: String,
    pub multi_select: bool,
}

impl Tab {
    fn find_command_by_name(&self, name: &str) -> Option<Rc<ListNode>> {
        self.tree.root().descendants().find_map(|node| {
            let node_value = node.value();
            (node_value.name == name && !node.has_children()).then_some(node_value.clone())
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use temp_dir::TempDir;

    pub(crate) fn create_temp_dir() -> TempDir {
        TempDir::with_prefix("linutil_test").unwrap()
    }

    pub(crate) fn create_tab() -> Tab {
        let command = Rc::new(ListNode {
            name: "command1".to_string(),
            description: "herro word :3".to_string(),
            command: Command::Raw("echo 'cat memes 🙀'".to_string()),
            task_list: "".to_string(),
            multi_select: false,
        });

        Tab {
            name: "TestTab".to_string(),
            tree: Tree::new(command),
        }
    }

    pub(crate) fn create_tab_list() -> TabList {
        TabList(vec![create_tab()], create_temp_dir())
    }

    #[test]
    fn test_find_command_by_name() {
        let tab = create_tab();
        let found_command = tab.find_command_by_name("command1");

        assert!(found_command.is_some());
        assert_eq!(found_command.unwrap().name, "command1");
        assert!(tab.find_command_by_name("nonexistent").is_none());
    }
}

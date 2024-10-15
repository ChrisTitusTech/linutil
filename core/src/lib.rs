mod config;
mod inner;

use std::rc::Rc;

use ego_tree::Tree;
use std::path::PathBuf;

pub use config::Config;
pub use inner::get_tabs;

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
    pub multi_selectable: bool,
}

#[derive(Clone, Hash, Eq, PartialEq)]
pub struct ListNode {
    pub name: String,
    pub description: String,
    pub command: Command,
    pub task_list: String,
}

impl Tab {
    pub fn find_command(&self, name: &str) -> Option<Rc<ListNode>> {
        self.tree.root().descendants().find_map(|node| {
            let value = node.value();
            if value.name == name && !node.has_children() {
                Some(value.clone())
            } else {
                None
            }
        })
    }
}

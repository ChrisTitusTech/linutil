mod inner;

use std::rc::Rc;

use ego_tree::Tree;
use std::path::PathBuf;

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

mod inner;

use ego_tree::Tree;
use std::path::PathBuf;

pub use inner::get_tabs;

#[derive(Clone, Hash, Eq, PartialEq)]
pub enum Command {
    Raw(String),
    LocalFile(PathBuf),
    None, // Directory
}

#[derive(Clone, Hash, Eq, PartialEq)]
pub struct Tab {
    pub name: String,
    pub tree: Tree<ListNode>,
}

#[derive(Clone, Hash, Eq, PartialEq)]
pub struct ListNode {
    pub name: String,
    pub command: Command,
}

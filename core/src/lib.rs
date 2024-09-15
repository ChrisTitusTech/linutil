mod inner;

use ego_tree::Tree;
use std::path::{Path, PathBuf};

pub use inner::{get_tabs, write_script_inner};

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
    pub multi_selectable: bool,
}

#[derive(Clone, Hash, Eq, PartialEq)]
pub struct ListNode {
    pub name: String,
    pub command: Command,
    pub revertable: bool,
    pub default_revertable: bool,
}

pub fn write_completed_script(script_path: &Path) {
    write_script_inner(script_path, false);
}

pub fn write_reverted_script(script_path: &Path) {
    write_script_inner(script_path, true);
}

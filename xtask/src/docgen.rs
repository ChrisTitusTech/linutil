use crate::DynError;
use linutil_core::{ListNode, Tab};

pub fn ttest() {
    let ok = linutil_core::get_tabs(false).1;

    for tab in ok {
        #[cfg(debug_assertions)]
        println!("Tab: {}", tab.name);

        for entry in tab.tree {
            #[cfg(debug_assertions)]
            println!("  Entry: {}", entry.name);
            println!("    Description: {}", entry.description);
        }
    }
}

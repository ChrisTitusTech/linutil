use std::fs;

use linutil_core::Command;

use crate::path;
use crate::DynError;

pub const USER_GUIDE: &str = "userguide.md";

pub fn userguide() -> Result<String, DynError> {
    let mut md = String::new();
    md.push_str("<!-- THIS FILE IS GENERATED BY cargo xtask docgen -->\n# Walkthrough\n");

    let tabs = linutil_core::get_tabs(false).1;

    for tab in tabs {
        #[cfg(debug_assertions)]
        println!("Tab: {}", tab.name);

        md.push_str(&format!("\n## {}\n\n", tab.name));

        for entry in tab.tree {
            if entry.command == Command::None {
                #[cfg(debug_assertions)]
                println!("  Directory: {}", entry.name);

                if entry.name != "root".to_string() {
                    md.push_str(&format!("\n### {}\n\n", entry.name));
                }

                /* let current_dir = &entry.name;

                if *current_dir != "root".to_string() {
                    md.push_str(&format!(
                        "\n<details><summary>{}</summary>\n\n",
                        current_dir
                    ));
                } */ // Commenting this for now, might be a good idea later
            } else {
                #[cfg(debug_assertions)]
                println!("    Entry: {}", entry.name);
                #[cfg(debug_assertions)]
                println!("      Description: {}", entry.description);

                md.push_str(&format!("- **{}**: {}\n", entry.name, entry.description));
            }
        }
    }

    Ok(md)
}

pub fn write(file: &str, data: &str) {
    let path = path::docs().join(file);
    fs::write(path, data).unwrap_or_else(|_| panic!("Could not write to {}", file));
}

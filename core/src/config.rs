use serde::Deserialize;
use std::path::Path;
use std::process;

#[derive(Deserialize)]
pub struct Config {
    pub auto_execute: Vec<String>,
}

impl Config {
    pub fn from_file(path: &Path) -> Self {
        let content = match std::fs::read_to_string(path) {
            Ok(content) => content,
            Err(e) => {
                eprintln!("Failed to read config file {}: {}", path.display(), e);
                process::exit(1);
            }
        };

        match toml::from_str(&content) {
            Ok(config) => config,
            Err(e) => {
                eprintln!("Failed to parse config file: {}", e);
                process::exit(1);
            }
        }
    }
}

use crate::theme::Theme;
use std::path::PathBuf;

pub struct AppState {
    /// Selected theme
    pub theme: Theme,
    /// Path to the root of the unpacked files in /tmp
    pub temp_path: PathBuf,
}

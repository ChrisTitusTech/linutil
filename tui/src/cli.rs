use crate::theme::Theme;
use clap::Parser;
use std::path::PathBuf;

#[derive(Debug, Parser, Clone)]
pub struct Args {
    /// Path to the configuration file
    #[arg(short, long)]
    pub config: Option<PathBuf>,

    /// Set the theme to use in the application
    #[arg(short, long, value_enum)]
    #[arg(default_value_t = Theme::Default)]
    pub theme: Theme,

    /// Skip confirmation prompt before executing commands
    #[arg(short = 'y', long)]
    pub skip_confirmation: bool,

    /// Show all available options, disregarding compatibility checks (UNSAFE)
    #[arg(short = 'u', long)]
    pub override_validation: bool,

    /// Bypass the terminal size limit
    #[arg(short = 's', long)]
    pub size_bypass: bool,

    /// Enable mouse interaction
    #[arg(short = 'm', long)]
    pub mouse: bool,

    /// Bypass root user check
    #[arg(short = 'r', long)]
    pub bypass_root: bool,
}

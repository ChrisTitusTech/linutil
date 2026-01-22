use clap::ValueEnum;
use ratatui::style::Color;

// Add the Theme name here for a new theme
// This is more secure than the previous list
// We cannot index out of bounds, and we are giving
// names to our various themes, making it very clear
// This will make it easy to add new themes
#[derive(Clone, Debug, PartialEq, Default, ValueEnum, Copy)]
pub enum Theme {
    #[default]
    Default,
    Compatible,
}

impl Theme {
    pub const fn dir_color(&self) -> Color {
        match self {
            Theme::Default => Color::LightCyan,
            Theme::Compatible => Color::Cyan,
        }
    }

    pub const fn cmd_color(&self) -> Color {
        match self {
            Theme::Default => Color::White,
            Theme::Compatible => Color::LightGreen,
        }
    }

    pub const fn multi_select_disabled_color(&self) -> Color {
        match self {
            Theme::Default => Color::DarkGray,
            Theme::Compatible => Color::DarkGray,
        }
    }

    pub const fn tab_color(&self) -> Color {
        match self {
            Theme::Default => Color::Yellow,
            Theme::Compatible => Color::LightYellow,
        }
    }

    pub const fn dir_icon(&self) -> &'static str {
        match self {
            Theme::Default => "[D]",
            Theme::Compatible => "[D]",
        }
    }

    pub const fn cmd_icon(&self) -> &'static str {
        match self {
            Theme::Default => "[*]",
            Theme::Compatible => "[*]",
        }
    }

    pub const fn tab_icon(&self) -> &'static str {
        match self {
            Theme::Default => ">> ",
            Theme::Compatible => ">  ",
        }
    }

    pub const fn multi_select_icon(&self) -> &'static str {
        match self {
            Theme::Default => "*",
            Theme::Compatible => "*",
        }
    }

    pub const fn success_color(&self) -> Color {
        match self {
            Theme::Default => Color::LightGreen,
            Theme::Compatible => Color::Green,
        }
    }

    pub const fn fail_color(&self) -> Color {
        match self {
            Theme::Default => Color::LightRed,
            Theme::Compatible => Color::Red,
        }
    }

    pub const fn focused_color(&self) -> Color {
        match self {
            Theme::Default => Color::LightBlue,
            Theme::Compatible => Color::LightCyan,
        }
    }

    pub const fn search_preview_color(&self) -> Color {
        match self {
            Theme::Default => Color::DarkGray,
            Theme::Compatible => Color::Gray,
        }
    }

    pub const fn unfocused_color(&self) -> Color {
        match self {
            Theme::Default => Color::Gray,
            Theme::Compatible => Color::DarkGray,
        }
    }
}

impl Theme {
    pub fn next(&mut self) {
        let position = *self as usize;
        let types = Theme::value_variants();
        *self = types[(position + 1) % types.len()];
    }

    pub fn prev(&mut self) {
        let position = *self as usize;
        let types = Theme::value_variants();
        *self = types[(position + types.len() - 1) % types.len()];
    }
}

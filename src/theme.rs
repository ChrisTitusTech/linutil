use clap::ValueEnum;
use ratatui::style::Color;

// Add the Theme name here for a new theme
// This is more secure than the previous list
// We cannot index out of bounds, and we are giving
// names to our various themes, making it very clear
#[derive(Clone, Debug, PartialEq, Default, ValueEnum, Copy)]
pub enum Theme {
    #[default]
    Default,
    Compatible,
}

impl Theme {
    pub fn dir_color(&self) -> Color {
        match self {
            Theme::Default => Color::Blue,
            Theme::Compatible => Color::Blue,
        }
    }

    pub fn cmd_color(&self) -> Color {
        match self {
            Theme::Default => Color::Rgb(204, 224, 208),
            Theme::Compatible => Color::LightGreen,
        }
    }

    pub fn dir_icon(&self) -> &'static str {
        match self {
            Theme::Default => "  ",
            Theme::Compatible => "[DIR]",
        }
    }

    pub fn cmd_icon(&self) -> &'static str {
        match self {
            Theme::Default => "  ",
            Theme::Compatible => "[CMD]",
        }
    }

    pub fn success_color(&self) -> Color {
        match self {
            Theme::Default => Color::Rgb(199, 55, 44),
            Theme::Compatible => Color::Green,
        }
    }

    pub fn fail_color(&self) -> Color {
        match self {
            Theme::Default => Color::Rgb(5, 255, 55),
            Theme::Compatible => Color::Red,
        }
    }
}

impl Theme {
    #[allow(unused)]
    pub fn next(self) -> Self {
        let position = self as usize;
        let types = Theme::value_variants();
        types[(position + 1) % types.len()].into()
    }

    #[allow(unused)]
    pub fn prev(self) -> Self {
        let position = self as usize;
        let types = Theme::value_variants();
        types[(position + types.len() - 1) % types.len()].into()
    }
}

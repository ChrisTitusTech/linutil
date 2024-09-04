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
    CatpuccinMocha,
}

impl Theme {
    pub fn dir_color(&self) -> Color {
        match self {
            Theme::Default => Color::Blue,
            Theme::Compatible => Color::Blue,
            // Blue
            Theme::CatpuccinMocha => Color::Rgb(137, 180, 250),
        }
    }

    pub fn cmd_color(&self) -> Color {
        match self {
            Theme::Default => Color::Rgb(204, 224, 208),
            Theme::Compatible => Color::LightGreen,
            // Teal
            Theme::CatpuccinMocha => Color::Rgb(148, 226, 213),
        }
    }

    pub fn tab_color(&self) -> Color {
        match self {
            Theme::Default => Color::Gray,
            Theme::Compatible => Color::Gray,
            // Blue
            Theme::CatpuccinMocha => Color::Rgb(137, 180, 250),
        }
    }

    pub fn dir_icon(&self) -> &'static str {
        match self {
            Theme::Compatible => "[DIR]",
            _ => "  ",
        }
    }

    pub fn cmd_icon(&self) -> &'static str {
        match self {
            Theme::Compatible => "[CMD]",
            _ => "  ",
        }
    }

    pub fn tab_icon(&self) -> &'static str {
        match self {
            Theme::Compatible => ">> ",
            _ => "  ",
        }
    }

    pub fn success_color(&self) -> Color {
        match self {
            Theme::Default => Color::Rgb(199, 55, 44),
            Theme::Compatible => Color::Green,
            // Green
            Theme::CatpuccinMocha => Color::Rgb(166, 227, 161),
        }
    }

    pub fn fail_color(&self) -> Color {
        match self {
            Theme::Default => Color::Rgb(5, 255, 55),
            Theme::Compatible => Color::Red,
            // Red
            Theme::CatpuccinMocha => Color::Rgb(243, 139, 168),
        }
    }

    pub fn cursor_color(&self) -> Color {
        match self {
            Theme::Default => Color::LightYellow,
            Theme::Compatible => Color::LightYellow,
            // Rosewater
            Theme::CatpuccinMocha => Color::Rgb(245, 224, 220),
        }
    }

    pub fn focused_color(&self) -> Color {
        match self {
            Theme::Default => Color::White,
            Theme::Compatible => Color::White,
            // Lavender
            Theme::CatpuccinMocha => Color::Rgb(180, 190, 254),
        }
    }

    pub fn unfocused_color(&self) -> Color {
        match self {
            Theme::Default => Color::DarkGray,
            Theme::Compatible => Color::DarkGray,
            // Overlay 0
            Theme::CatpuccinMocha => Color::Rgb(147, 153, 178),
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

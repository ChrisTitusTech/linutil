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
    fn get_color_variant(&self, default: Color, compatible: Color) -> Color {
        match self {
            Theme::Default => default,
            Theme::Compatible => compatible,
        }
    }

    fn get_icon_variant(&self, default: &'static str, compatible: &'static str) -> &'static str {
        match self {
            Theme::Default => default,
            Theme::Compatible => compatible,
        }
    }

    pub fn dir_color(&self) -> Color {
        self.get_color_variant(Color::Blue, Color::Blue)
    }

    pub fn cmd_color(&self) -> Color {
        self.get_color_variant(Color::Rgb(204, 224, 208), Color::LightGreen)
    }

    pub fn multi_select_disabled_color(&self) -> Color {
        self.get_color_variant(Color::DarkGray, Color::DarkGray)
    }

    pub fn tab_color(&self) -> Color {
        self.get_color_variant(Color::Rgb(255, 255, 85), Color::Yellow)
    }

    pub fn dir_icon(&self) -> &'static str {
        self.get_icon_variant("  ", "[DIR]")
    }

    pub fn cmd_icon(&self) -> &'static str {
        self.get_icon_variant("  ", "[CMD]")
    }

    pub fn tab_icon(&self) -> &'static str {
        self.get_icon_variant("  ", ">> ")
    }

    pub fn multi_select_icon(&self) -> &'static str {
        self.get_icon_variant("", "*")
    }

    pub fn success_color(&self) -> Color {
        self.get_color_variant(Color::Rgb(5, 255, 55), Color::Green)
    }

    pub fn fail_color(&self) -> Color {
        self.get_color_variant(Color::Rgb(199, 55, 44), Color::Red)
    }

    pub fn focused_color(&self) -> Color {
        self.get_color_variant(Color::LightBlue, Color::LightBlue)
    }

    pub fn search_preview_color(&self) -> Color {
        self.get_color_variant(Color::DarkGray, Color::DarkGray)
    }

    pub fn unfocused_color(&self) -> Color {
        self.get_color_variant(Color::Gray, Color::Gray)
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

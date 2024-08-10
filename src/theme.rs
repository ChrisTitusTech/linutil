use clap::builder::PossibleValue;
use clap::ValueEnum;
use ratatui::style::Color;

// Add the Theme name here for a new theme
// This is more secure than the previous list
// We cannot index out of bounds, and we are giving
// names to our various themes, making it very clear
#[derive(Clone, Debug, PartialEq, Default)]
pub enum ThemeType {
    #[default]
    Default,
    Compatible,
}

// Clap uses the `ValueEnum` trait to convert the user input directly into a
// `ThemeType` from the command line.
const THEME_TYPES: &[ThemeType] = &[ThemeType::Default, ThemeType::Compatible];
impl ValueEnum for ThemeType {
    fn value_variants<'a>() -> &'a [Self] {
        THEME_TYPES
    }

    fn from_str(input: &str, ignore_case: bool) -> Result<Self, String> {
        let input = if ignore_case {
            input.to_lowercase()
        } else {
            input.to_owned()
        };

        match input.as_str() {
            "default" => Ok(Self::Default),
            "compatible" => Ok(Self::Compatible),
            _ => Err(format!("Invalid theme: {}", input)),
        }
    }

    fn to_possible_value(&self) -> Option<PossibleValue> {
        Some(match self {
            Self::Default => PossibleValue::new("default"),
            Self::Compatible => PossibleValue::new("compatible"),
        })
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct Theme {
    pub dir_color: Color,
    pub cmd_color: Color,
    pub dir_icon: &'static str,
    pub cmd_icon: &'static str,
    pub success_color: Color,
    pub fail_color: Color,
}

// Provides the ability to cycle through the available themes at runtime
// while building on the ValueEnum implementation
impl Theme {
    // I left them unused, so you can accept the PR even if you don't
    // want this feature.
    #[allow(unused)]
    pub fn next(self) -> Self {
        let theme_type: ThemeType = self.into();
        let position = theme_type as usize;
        let types = ThemeType::value_variants();

        types[(position + 1) % types.len()].clone().into()
    }

    #[allow(unused)]
    pub fn prev(self) -> Self {
        let theme_type: ThemeType = self.into();
        let position = theme_type as usize;
        let types = ThemeType::value_variants();

        types[(position + types.len() - 1) % types.len()]
            .clone()
            .into()
    }
}

impl Into<ThemeType> for Theme {
    // We could branch here rather than converting until we find,
    // but this does not require to be maintained in the future
    fn into(self) -> ThemeType {
        let types = ThemeType::value_variants();

        types
            .iter()
            .find(|t| {
                let theme: Theme = t.into();
                theme == self
            })
            .unwrap_or(&ThemeType::Default)
            .clone()
    }
}
impl From<ThemeType> for Theme {
    fn from(theme: ThemeType) -> Self {
        Theme::from(&theme)
    }
}

impl From<&ThemeType> for Theme {
    fn from(theme: &ThemeType) -> Self {
        Theme::from(&theme)
    }
}
impl From<&&ThemeType> for Theme {
    // Add Theme properties here for a new theme
    fn from(theme: &&ThemeType) -> Self {
        match theme {
            ThemeType::Default => Theme::default(),
            ThemeType::Compatible => Theme {
                dir_color: Color::Blue,
                cmd_color: Color::LightGreen,
                dir_icon: "[DIR]",
                cmd_icon: "[CMD]",
                success_color: Color::Green,
                fail_color: Color::Red,
            },
        }
    }
}

// Makes it very clear what is the default theme
impl Default for Theme {
    fn default() -> Self {
        Theme {
            dir_color: Color::Blue,
            cmd_color: Color::Rgb(204, 224, 208),
            dir_icon: "  ",
            cmd_icon: "  ",
            fail_color: Color::Rgb(199, 55, 44),
            success_color: Color::Rgb(5, 255, 55),
        }
    }
}

use clap::ValueEnum;
use ratatui::style::Color;
use std::sync::OnceLock;

type Rgb = (u8, u8, u8);

struct Palette {
    bg: Rgb,
    text: Rgb,
    muted: Rgb,
    tab_unselected: Rgb,
    flags: Rgb,
    success: Rgb,
    info: Rgb,
    selection: Rgb,
    folders: Rgb,
    fail: Rgb,
    focused: Rgb,
    unfocused: Rgb,
}

const LINUTIL: Palette = Palette {
    bg: (0x16, 0x16, 0x16),
    text: (0xae, 0xb4, 0xd2),
    muted: (0x80, 0x85, 0x9f),
    tab_unselected: (0x4d, 0x50, 0x5f),
    flags: (0xae, 0x90, 0xe2),
    success: (0x73, 0xda, 0xca),
    info: (0x44, 0x9c, 0xa9),
    selection: (0x30, 0x33, 0x3d),
    folders: (0xe0, 0xaf, 0x68),
    fail: (0xf7, 0x76, 0x8e),
    focused: (0x55, 0xad, 0xff),
    unfocused: (0x60, 0x65, 0x79),
};

// Colours that are too faint for a TUI are raised to the contrast limits in the
// tests below.
const NORD: Palette = Palette {
    bg: (0x2e, 0x34, 0x40),
    text: (0xec, 0xef, 0xf4),
    muted: (0x92, 0x9c, 0xad),
    tab_unselected: (0x62, 0x6b, 0x79),
    flags: (0x8f, 0xbc, 0xbb),
    success: (0xa3, 0xbe, 0x8c),
    info: (0x88, 0xc0, 0xd0),
    selection: (0x43, 0x4c, 0x5e),
    folders: (0x88, 0xc0, 0xd0),
    fail: (0xcf, 0x88, 0x8f),
    focused: (0x81, 0xa1, 0xc1),
    unfocused: (0x59, 0x61, 0x72),
};

const TOKYO_NIGHT: Palette = Palette {
    bg: (0x1a, 0x1b, 0x26),
    text: (0xc8, 0xd3, 0xf5),
    muted: (0x82, 0x8b, 0xb8),
    tab_unselected: (0x4f, 0x54, 0x70),
    flags: (0xff, 0x96, 0x6c),
    success: (0xc3, 0xe8, 0x8d),
    info: (0x82, 0xaa, 0xff),
    selection: (0x2f, 0x32, 0x45),
    folders: (0x82, 0xaa, 0xff),
    fail: (0xff, 0x75, 0x7f),
    focused: (0xc0, 0x99, 0xff),
    unfocused: (0x73, 0x7a, 0xa2),
};

const ONE_DARK: Palette = Palette {
    bg: (0x28, 0x2c, 0x34),
    text: (0xb1, 0xb8, 0xc4),
    muted: (0x8c, 0x93, 0xa0),
    tab_unselected: (0x5d, 0x63, 0x6d),
    flags: (0xc6, 0x78, 0xdd),
    success: (0x98, 0xc3, 0x79),
    info: (0xd1, 0x9a, 0x66),
    selection: (0x3b, 0x41, 0x4b),
    folders: (0xe5, 0xc0, 0x7b),
    fail: (0xe1, 0x70, 0x78),
    focused: (0x61, 0xaf, 0xef),
    unfocused: (0x54, 0x5a, 0x65),
};

const MONOCHROME: Palette = Palette {
    bg: (0x22, 0x22, 0x22),
    text: (0xaa, 0xaa, 0xaa),
    muted: (0x90, 0x90, 0x90),
    tab_unselected: (0x5a, 0x5a, 0x5a),
    flags: (0xcc, 0xcc, 0xcc),
    success: (0xff, 0xff, 0xff),
    info: (0xcc, 0xcc, 0xcc),
    selection: (0x3a, 0x3a, 0x3a),
    folders: (0xff, 0xff, 0xff),
    fail: (0xff, 0x7b, 0x72),
    focused: (0xff, 0xff, 0xff),
    unfocused: (0x66, 0x66, 0x66),
};

const LUCENT_ORNG: Palette = Palette {
    bg: (0x0a, 0x0a, 0x0a),
    text: (0xee, 0xee, 0xee),
    muted: (0x80, 0x80, 0x80),
    tab_unselected: (0x4c, 0x4c, 0x4c),
    flags: (0xff, 0xf7, 0xf1),
    success: (0x6b, 0xa1, 0xe6),
    info: (0x56, 0xb6, 0xc2),
    selection: (0x29, 0x29, 0x29),
    folders: (0xec, 0x5b, 0x2b),
    fail: (0xe0, 0x6c, 0x75),
    focused: (0xee, 0x79, 0x48),
    unfocused: (0x53, 0x53, 0x53),
};

const GITHUB: Palette = Palette {
    bg: (0x0d, 0x11, 0x17),
    text: (0xc9, 0xd1, 0xd9),
    muted: (0x8b, 0x94, 0x9e),
    tab_unselected: (0x49, 0x50, 0x58),
    flags: (0xbc, 0x8c, 0xff),
    success: (0x3f, 0xb9, 0x50),
    info: (0xd2, 0x99, 0x22),
    selection: (0x28, 0x2d, 0x34),
    folders: (0xe3, 0xb3, 0x41),
    fail: (0xf8, 0x51, 0x49),
    focused: (0x58, 0xa6, 0xff),
    unfocused: (0x41, 0x47, 0x4e),
};

const MATERIAL: Palette = Palette {
    bg: (0x26, 0x32, 0x38),
    text: (0xee, 0xff, 0xff),
    muted: (0x84, 0x9b, 0xa3),
    tab_unselected: (0x58, 0x6a, 0x71),
    flags: (0xc7, 0x92, 0xea),
    success: (0xc3, 0xe8, 0x8d),
    info: (0xff, 0xcb, 0x6b),
    selection: (0x37, 0x47, 0x4f),
    folders: (0xff, 0xcb, 0x6b),
    fail: (0xf0, 0x71, 0x78),
    focused: (0x82, 0xaa, 0xff),
    unfocused: (0x50, 0x60, 0x67),
};

const FLEXOKI: Palette = Palette {
    bg: (0x10, 0x0f, 0x0f),
    text: (0xce, 0xcd, 0xc3),
    muted: (0x7c, 0x7b, 0x75),
    tab_unselected: (0x4f, 0x4e, 0x4b),
    flags: (0x8b, 0x7e, 0xc8),
    success: (0x87, 0x9a, 0x39),
    info: (0x3a, 0xa9, 0x9f),
    selection: (0x2c, 0x2b, 0x2a),
    folders: (0xda, 0x70, 0x2c),
    fail: (0xd2, 0x50, 0x44),
    focused: (0x43, 0x85, 0xbe),
    unfocused: (0x57, 0x56, 0x53),
};

#[derive(Clone, Debug, PartialEq, Default, ValueEnum, Copy)]
pub enum Theme {
    #[default]
    Default,
    Compatible,
    Nord,
    TokyoNight,
    OneDark,
    Monochrome,
    LucentOrng,
    Github,
    Material,
    Flexoki,
}

/// The themes `t` goes through. Compatible is left out: it is for terminals that
/// have no truecolor, where the others look the same as it does.
const CYCLE: [Theme; 9] = [
    Theme::Default,
    Theme::Nord,
    Theme::TokyoNight,
    Theme::OneDark,
    Theme::Monochrome,
    Theme::LucentOrng,
    Theme::Github,
    Theme::Material,
    Theme::Flexoki,
];

pub(crate) fn supports_truecolor(term: &str, colorterm: &str) -> bool {
    !matches!(term, "linux" | "dumb")
        && (matches!(colorterm, "truecolor" | "24bit") || term.ends_with("-direct"))
}

fn palette_color(theme: Theme, truecolor: bool, rgb: Rgb, fallback: Color) -> Color {
    if theme != Theme::Compatible && truecolor {
        Color::Rgb(rgb.0, rgb.1, rgb.2)
    } else {
        fallback
    }
}

/// Whether the terminal can show the themes' colours.
pub fn truecolor() -> bool {
    // Terminal capabilities do not change when cycling the application's theme.
    static TRUECOLOR: OnceLock<bool> = OnceLock::new();
    *TRUECOLOR.get_or_init(|| {
        supports_truecolor(
            &std::env::var("TERM").unwrap_or_default(),
            &std::env::var("COLORTERM").unwrap_or_default(),
        )
    })
}

impl Theme {
    pub const fn name(&self) -> &'static str {
        match self {
            Self::Default => "Linutil",
            Self::Compatible => "Compatible",
            Self::Nord => "Nord",
            Self::TokyoNight => "Tokyo Night",
            Self::OneDark => "One Dark",
            Self::Monochrome => "Monochrome",
            Self::LucentOrng => "Lucent-Orng",
            Self::Github => "GitHub",
            Self::Material => "Material",
            Self::Flexoki => "Flexoki",
        }
    }

    const fn palette(&self) -> &'static Palette {
        match self {
            Self::Default | Self::Compatible => &LINUTIL,
            Self::Nord => &NORD,
            Self::TokyoNight => &TOKYO_NIGHT,
            Self::OneDark => &ONE_DARK,
            Self::Monochrome => &MONOCHROME,
            Self::LucentOrng => &LUCENT_ORNG,
            Self::Github => &GITHUB,
            Self::Material => &MATERIAL,
            Self::Flexoki => &FLEXOKI,
        }
    }

    fn color(&self, rgb: Rgb, fallback: Color) -> Color {
        palette_color(*self, truecolor(), rgb, fallback)
    }

    pub fn bg(&self) -> Color {
        self.color(self.palette().bg, Color::Black)
    }

    pub fn dir_color(&self) -> Color {
        self.tab_color()
    }

    pub fn cmd_color(&self) -> Color {
        self.color(self.palette().text, Color::White)
    }

    pub fn muted(&self) -> Color {
        self.color(self.palette().muted, Color::Gray)
    }

    /// The 16-colour fallback stays Gray: the next colour down, DarkGray, is too
    /// dark to read on a Linux console.
    pub fn tab_unselected(&self) -> Color {
        self.color(self.palette().tab_unselected, Color::Gray)
    }

    pub fn purple(&self) -> Color {
        self.color(self.palette().flags, Color::LightMagenta)
    }

    pub fn green(&self) -> Color {
        self.color(self.palette().success, Color::LightGreen)
    }

    pub fn cyan(&self) -> Color {
        self.color(self.palette().info, Color::Cyan)
    }

    pub fn selection_bg(&self) -> Color {
        self.color(self.palette().selection, Color::DarkGray)
    }

    pub fn multi_select_disabled_color(&self) -> Color {
        self.muted()
    }

    pub fn tab_color(&self) -> Color {
        self.color(self.palette().folders, Color::Yellow)
    }

    pub const fn dir_icon(&self) -> &'static str {
        "[D]"
    }

    pub const fn cmd_icon(&self) -> &'static str {
        "[*]"
    }

    pub const fn tab_icon(&self) -> &'static str {
        "> "
    }

    pub const fn multi_select_icon(&self) -> &'static str {
        "*"
    }

    pub fn success_color(&self) -> Color {
        self.green()
    }

    pub fn fail_color(&self) -> Color {
        self.color(self.palette().fail, Color::LightRed)
    }

    pub fn focused_color(&self) -> Color {
        self.color(self.palette().focused, Color::LightBlue)
    }

    pub fn search_preview_color(&self) -> Color {
        self.muted()
    }

    pub fn unfocused_color(&self) -> Color {
        self.color(self.palette().unfocused, Color::DarkGray)
    }

    pub fn next(&mut self) {
        let position = CYCLE.iter().position(|theme| theme == self);
        *self = CYCLE[position.map_or(0, |position| (position + 1) % CYCLE.len())];
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn truecolor_detection_respects_console_and_explicit_capabilities() {
        assert!(supports_truecolor("xterm-256color", "truecolor"));
        assert!(supports_truecolor("xterm-256color", "24bit"));
        assert!(supports_truecolor("xterm-direct", ""));
        assert!(!supports_truecolor("linux", "truecolor"));
        assert!(!supports_truecolor("dumb", "truecolor"));
        assert!(!supports_truecolor("xterm-256color", ""));
    }

    #[test]
    fn compatible_theme_and_limited_terminals_use_ansi_colors() {
        let rgb = (0x55, 0xad, 0xff);
        assert_eq!(
            palette_color(Theme::Default, true, rgb, Color::LightBlue),
            Color::Rgb(0x55, 0xad, 0xff)
        );
        assert_eq!(
            palette_color(Theme::Compatible, true, rgb, Color::LightBlue),
            Color::LightBlue
        );
        assert_eq!(
            palette_color(Theme::Default, false, rgb, Color::LightBlue),
            Color::LightBlue
        );
        assert_eq!(
            palette_color(Theme::Nord, false, rgb, Color::LightBlue),
            Color::LightBlue
        );
        assert_eq!(
            palette_color(Theme::Nord, true, rgb, Color::LightBlue),
            Color::Rgb(0x55, 0xad, 0xff)
        );
    }

    fn contrast(a: Rgb, b: Rgb) -> f64 {
        let luminance = |(r, g, b): Rgb| {
            let channel = |value: u8| {
                let value = f64::from(value) / 255.0;
                if value <= 0.03928 {
                    value / 12.92
                } else {
                    ((value + 0.055) / 1.055).powf(2.4)
                }
            };
            0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        };
        let (a, b) = (luminance(a), luminance(b));
        (a.max(b) + 0.05) / (a.min(b) + 0.05)
    }

    #[test]
    fn every_theme_stays_readable() {
        for theme in CYCLE {
            let palette = theme.palette();
            let bg = palette.bg;
            assert!(contrast(palette.text, bg) >= 6.5, "{theme:?} text");
            for (name, color) in [
                ("muted", palette.muted),
                ("flags", palette.flags),
                ("success", palette.success),
                ("info", palette.info),
                ("folders", palette.folders),
                ("fail", palette.fail),
                ("focused", palette.focused),
            ] {
                assert!(contrast(color, bg) >= 4.45, "{theme:?} {name}");
            }
            assert!(
                contrast(palette.unfocused, bg) >= 1.95,
                "{theme:?} unfocused"
            );
            assert!(
                contrast(palette.selection, bg) >= 1.3,
                "{theme:?} selection"
            );
            let tab = contrast(palette.tab_unselected, bg);
            assert!((2.2..=2.5).contains(&tab), "{theme:?} tab_unselected {tab}");
            assert_ne!(palette.unfocused, palette.focused, "{theme:?} borders");
        }
    }

    #[test]
    fn t_goes_through_the_dark_themes_and_wraps() {
        let mut theme = Theme::Default;
        for expected in CYCLE.iter().cycle().skip(1).take(CYCLE.len()) {
            theme.next();
            assert_eq!(theme, *expected);
        }
        assert_eq!(theme, Theme::Default);
        let mut theme = Theme::Compatible;
        theme.next();
        assert_eq!(theme, Theme::Default);
    }
}

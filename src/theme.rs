use ratatui::style::Color;

pub static mut THEME_IDX: usize = 1;

pub struct Theme {
    pub dir_color: Color,
    pub cmd_color: Color,
    pub dir_icon: &'static str,
    pub cmd_icon: &'static str,
    pub success_color: Color,
    pub fail_color: Color,
}

pub const THEMES: [Theme; 2] = [
    Theme {
        dir_color: Color::Blue,
        cmd_color: Color::LightGreen,
        dir_icon: "[DIR]",
        cmd_icon: "[CMD]",
        success_color: Color::Green,
        fail_color: Color::Red,
    },
    Theme {
        dir_color: Color::Blue,
        cmd_color: Color::Rgb(204, 224, 208),
        dir_icon: "  ",
        cmd_icon: "  ",
        fail_color: Color::Rgb(199, 55, 44),
        success_color: Color::Rgb(5, 255, 55),
    },
];

pub fn get_theme() -> &'static Theme {
    return &THEMES[unsafe {THEME_IDX} ];
}

pub fn set_theme(idx: usize){
    unsafe {THEME_IDX = idx};
}

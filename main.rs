use iced::{
    Alignment, Backward,Sandbox, Settings,
},

pub fn main() -> iced::Result {
    RustUI::run(Settings::default())
}

struct RustUI {
    theme: Theme,
    page: Page,
    login_field: LoginField
}

struct LoginField {email: String, password: String}

#[derive(Debug, Clone, PartialEq, Eq)]
enum Page {Login, Register}

enum Message {
    ToggleTheme, 
    LoginSubmit,
}
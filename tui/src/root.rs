use crate::{
    float::Float, float::FloatContent, floating_text::FloatingText, state::AppState, theme::Theme,
};
use std::path::PathBuf;

#[cfg(unix)]
use nix::unistd::Uid;

pub fn create_app_state(
    config_path: Option<PathBuf>,
    theme: Theme,
    override_validation: bool,
    size_bypass: bool,
    skip_confirmation: bool,
) -> AppState {
    #[cfg(unix)]
    {
        if Uid::effective().is_root() {
            let mut state = AppState::new(
                config_path,
                theme,
                override_validation,
                size_bypass,
                skip_confirmation,
            );

            let warning = FloatingText::new(
                "\
                WARNING: You are running this utility as root!\n\n\
                This means you have full system access and commands can potentially damage your system if used incorrectly.\n\n\
                Please proceed with caution and make sure you understand what each command does before executing it.\
                ".into(),
                "Root User Warning",
                true,
            );
            let float: Float<dyn FloatContent> = Float::new(Box::new(warning), 60, 40);
            state.set_float_window(float);
            return state;
        }
    }

    AppState::new(
        config_path,
        theme,
        override_validation,
        size_bypass,
        skip_confirmation,
    )
}

use crate::floating_text::FloatingText;

#[cfg(unix)]
use nix::unistd::Uid;

const ROOT_WARNING: &str = "WARNING: You are running this utility as root!\n
This means you have full system access and commands can potentially damage your system if used incorrectly.\n
Please proceed with caution and make sure you understand what each script does before executing it.";

#[cfg(unix)]
pub fn check_root_status(bypass_root: bool) -> Option<FloatingText<'static>> {
    if bypass_root {
        return None;
    }

    Uid::effective().is_root().then_some(FloatingText::new(
        ROOT_WARNING.into(),
        "Root User Warning",
        true,
    ))
}

use packagemanagers::PackageManager;
use std::collections::HashMap;

pub mod packagemanagers;

pub struct System {
    pub id: Box<str>,
    pub pretty_name: Box<str>,
    pub package_manager: Option<PackageManager>,
}

impl System {
    pub fn info() -> System {
        let (id, pretty_name) = get_distribution();

        let package_manager =
            get_package_manager(id.as_ref()).and_then(|name| packagemanagers::get(name));

        Self {
            id,
            pretty_name,
            package_manager,
        }
    }
}

fn get_package_manager(distro: &str) -> Option<&'static str> {
    let package_managers = [
        ("fedora", "dnf"),
        ("debian", "apt-get"),
        ("arch", "pacman"),
        ("opensuse", "zypper"),
    ];

    package_managers
        .into_iter()
        .find(|(key, _)| key == &distro)
        .map(|(_, value)| value)
}

fn get_distribution() -> (Box<str>, Box<str>) {
    let mut info = get_os_info();

    let id = info.remove("id").unwrap_or("unknown".into());
    let pretty_name = info.remove("pretty_name").unwrap_or("unknown".into());

    (id, pretty_name)
}

fn get_os_info() -> HashMap<Box<str>, Box<str>> {
    // os-release existing is a precondition which should be required. Therefore, we'll use expect() to specify why we expect this always to return an Ok value
    let contents = std::fs::read_to_string("/etc/os-release")
        .expect("os-release should exist on all Linux systems.");

    contents
        .lines()
        .filter_map(|line| {
            line.split_once('=')
                .map(|(key, value)| (key.to_lowercase().into(), value.trim_matches('"').into()))
        })
        // The return type is implied, so we don't need to specify it to collect() in this case.
        .collect()
}

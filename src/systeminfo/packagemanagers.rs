#[derive(Clone)]
pub struct PackageManager {
    pub name: &'static str,
    pub install_command: &'static str,
    pub uninstall_command: &'static str,
    pub update_command: &'static str,
}

static PACKAGE_MANAGERS: [PackageManager; 5] = [
    PackageManager {
        name: "dnf",
        install_command: "dnf install",
        uninstall_command: "dnf remove",
        update_command: "dnf update",
    },
    PackageManager {
        name: "pacman",
        install_command: "pacman -Sy",
        uninstall_command: "pacman -Rs",
        update_command: "pacman -Syu",
    },
    PackageManager {
        name: "apt",
        install_command: "apt install",
        uninstall_command: "apt remove",
        update_command: "apt update",
    },
    PackageManager {
        name: "zypper",
        install_command: "zypper install",
        uninstall_command: "zypper remove",
        update_command: "zypper update",
    },
    PackageManager {
        name: "yum",
        install_command: "yum install",
        uninstall_command: "yum remove",
        update_command: "yum update",
    },
];

pub fn get(name: String) -> Option<PackageManager> {
    for p in &PACKAGE_MANAGERS {
        if p.name == name {
            return Some(p.clone())
        }
    }

    None
}
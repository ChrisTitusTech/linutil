#[derive(Clone)]
pub struct PackageManager {
    pub name: &'static str,
    pub install_command: &'static str,
    pub uninstall_command: &'static str,
    pub update_command: &'static str,
}

// Const should be used if we don't need to allocate anything on the heap. Constant values are inlined, essentially think of it this array replacing the variable in the code, rather than just referencing it.
// Static variables are, on the other hand, allocated into memory at runtime and are never dropped. They are preferred if you need heap allocations or (interior) mutability.
const PACKAGE_MANAGERS: [PackageManager; 5] = [
    PackageManager {
        name: "dnf",
        install_command: "install",
        uninstall_command: "remove",
        update_command: "update",
    },
    PackageManager {
        name: "pacman",
        install_command: "-Sy",
        uninstall_command: "-Rs",
        update_command: "-Syu",
    },
    PackageManager {
        name: "apt",
        install_command: "install",
        uninstall_command: "remove",
        update_command: "update",
    },
    PackageManager {
        name: "zypper",
        install_command: "install",
        uninstall_command: "remove",
        update_command: "update",
    },
    PackageManager {
        name: "yum",
        install_command: "install",
        uninstall_command: "remove",
        update_command: "update",
    },
];

// Good practice is to take in a pointer whenever you don't need ownership.
pub fn get(name: &str) -> Option<PackageManager> {
    // Iterators are typically preferred to traditional for loops in Rust.
    // This line should be pretty self explanatory. We turn the package managers into an iterator of owned values (with into_iter()), then find the first one that matches the name string slice.
    // find() returns an optional value, so we can return it directly (with an implicit return)
    PACKAGE_MANAGERS.into_iter().find(|p| p.name == name)
}

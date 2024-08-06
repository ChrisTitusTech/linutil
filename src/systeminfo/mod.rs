use std::collections::HashMap;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;

pub mod packagemanagers;

pub struct System {
    pub id: String,
    pub pretty_name: String,
    pub package_manager: String,
    pub install_command: String,
    pub uninstall_command: String,
    pub update_command: String
}

impl System {
    pub fn info() -> System {
        let (distro, pretty_name): (String, String) = get_distribution();
        let package_manager: String = get_package_manager(&distro);
        
        let pm: packagemanagers::PackageManager;

        match packagemanagers::get(package_manager) {
            Some(value) => pm = value,
            None => panic!("Could not find a suitable package manager")
        }
    
        let s: System = System {
            id: distro,
            pretty_name: pretty_name,
            package_manager: pm.name.to_string(),
            install_command: pm.install_command.to_string(),
            uninstall_command: pm.uninstall_command.to_string(),
            update_command: pm.update_command.to_string(),
        };

        return s;
    }
}

fn get_package_manager(distro: &String) -> String {
    // Package manager map
    let mut map: HashMap<String, String> = HashMap::new();
    map.insert("fedora".to_string(), "dnf".to_string());
    map.insert("debian".to_string(), "apt".to_string());
    map.insert("arch".to_string(), "pacman".to_string());
    map.insert("opensuse".to_string(), "zypper".to_string());

    match map.get(&distro.to_string()) {
        Some(val) => return val.to_string(),
        None => panic!("Could not find a suitable package manager for your system")
    }
}

fn get_distribution() -> (String, String) {
    let info: HashMap<String, String> = get_os_info();

    // Retrieve the value for the key
    let id: String;
    let pretty_name: String;
    match info.get(&"id".to_string()) {
        Some(value) => id = value.to_string(),
        None => id = "unknown".to_string(),
    }

    match info.get(&"pretty_name".to_string()) {
        Some(value) => pretty_name = value.to_string(),
        None => pretty_name = "unknown".to_string(),
    }

    return (id, pretty_name);
}

fn get_os_info() -> HashMap<String, String> {
    let mut map: HashMap<String, String> = HashMap::new();

    if let Ok(lines) = read_lines("/etc/os-release") {
        // Consumes the iterator, returns an (Optional) String
        for line in lines.flatten() {
            let vals: Vec<&str> = line.split("=").collect();
            let key = vals[0];
            let value = vals[1];

            map.insert(key.to_string().to_lowercase(), value.to_string());
        }
    }

    return map;
}

// The output is wrapped in a Result to allow matching on errors.
// Returns an Iterator to the Reader of the lines of the file.
fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}
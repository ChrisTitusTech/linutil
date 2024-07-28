use std::{
    collections::HashMap,
    env, fs,
    io::{Read, Write},
    path::{Path, PathBuf},
};

const SCRIPT_PATH: &str = "src/commands/";

fn main() {
    // Rerun build step if the build script is modified
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed={}", SCRIPT_PATH);

    let out_dir = env::var("OUT_DIR").unwrap();
    let file_list = get_script_list(Path::new(SCRIPT_PATH));
    complete_scripts(file_list, out_dir.into());
}

fn get_script_list(path: &Path) -> Vec<PathBuf> {
    let paths = path.read_dir().unwrap();
    paths
        .into_iter()
        .flatten()
        .filter_map(|entry| {
            let path = entry.path();
            // Recursively iterate through directories
            if entry.file_type().map_or(false, |f| f.is_dir()) {
                get_script_list(&path).into()
            } else {
                is_script(&path).then_some(vec![path])
            }
        })
        .flatten()
        .collect()
}

fn complete_scripts(files: Vec<PathBuf>, out_dir: PathBuf) {
    for file in files {
        // Rerun build step if any script is modified
        println!("cargo:rerun-if-changed={}", file.display());

        let mut out_file = create_out_file(&file, out_dir.clone());
        let mut map = HashMap::new();
        let new_file = replace_source(file, &mut map);

        out_file.write_all(new_file.as_bytes()).unwrap()
    }
}

fn replace_source(file: PathBuf, used_paths: &mut HashMap<PathBuf, usize>) -> String {
    let contents = fs::read_to_string(&file).unwrap();
    let filedir = file.parent().unwrap();

    let count = used_paths.entry(file.clone()).or_insert(0);
    *count += 1;
    if *count > 5 {
        panic!(
            "Sourced {} too many times. Check for circular dependencies",
            file.canonicalize().unwrap_or(file).display()
        );
    }

    contents
        .lines()
        .map(|line| {
            if line.starts_with(". ") || line.starts_with("source ") {
                let (_, sourced_file) = line.split_once(' ').unwrap();
                let sourced_file = filedir.join(sourced_file.trim_start());
                if !(sourced_file.exists() && has_shell_ext(&sourced_file)) {
                    return line.to_string();
                }
                replace_source(sourced_file, used_paths)
            } else {
                line.to_string()
            }
        })
        .collect::<Vec<_>>()
        .join("\n")
}

fn create_out_file(file: &Path, out_dir: PathBuf) -> fs::File {
    let out_file = out_dir.clone().join(file);
    let out_file_parent = out_file.parent().unwrap();
    std::fs::create_dir_all(out_file_parent).unwrap();
    fs::File::create(out_file).unwrap()
}

fn is_script(file: &Path) -> bool {
    has_shell_ext(file) && starts_with_shebang(file)
}

fn has_shell_ext(file: &Path) -> bool {
    file.extension().map_or(true, |ext| ext == "sh")
}

fn starts_with_shebang(file: &Path) -> bool {
    fs::File::open(file).map_or(false, |mut file| {
        let mut two_byte_buffer = [0; 2];
        file.read_exact(&mut two_byte_buffer).is_ok() && two_byte_buffer == *b"#!"
    })
}

use std::{
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
                let is_script = has_shell_ext(&path) && starts_with_shebang(&path);
                is_script.then_some(vec![path])
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
        let new_file = replace_source(&file).unwrap();

        out_file.write_all(new_file.as_bytes()).unwrap()
    }
}

fn replace_source(file: &Path) -> Result<String, std::io::Error> {
    let contents = fs::read_to_string(file)?;
    let filedir = file.parent().unwrap();

    let new_contents = contents
        .lines()
        .map(|line| {
            if line.starts_with(". ") || line.starts_with("source ") {
                let (_, sourced_file) = line.split_once(' ').unwrap();
                let sourced_file = filedir.join(sourced_file);
                replace_source(&sourced_file).unwrap_or(line.to_string())
            } else {
                line.to_string()
            }
        })
        .collect::<Vec<_>>()
        .join("\n");

    Ok(new_contents)
}

fn create_out_file(file: &Path, out_dir: PathBuf) -> fs::File {
    let out_file = out_dir.clone().join(file);
    let out_file_parent = out_file.parent().unwrap();
    std::fs::create_dir_all(out_file_parent).unwrap();
    fs::File::create(out_file).unwrap()
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

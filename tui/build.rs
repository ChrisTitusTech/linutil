fn main() {
    // Add current date as a variable to be displayed in the 'Linux Toolbox' text.
    println!(
        "cargo:rustc-env=BUILD_DATE={}",
        chrono::Local::now().format("%Y-%m-%d")
    );
}

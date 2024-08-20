fn main() {
    // Rebuild program if any file in commands directory changes.
    println!("cargo:rerun-if-changed=src/commands");
}

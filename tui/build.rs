// Build script to inject a richer version string into the binary title
// Prefer including git metadata when available, and fall back to Cargo pkg version.

use std::{env, process::Command};

fn main() {
    // Always rerun if HEAD changes or Cargo.toml version changes
    println!("cargo:rerun-if-changed=Cargo.toml");
    println!("cargo:rerun-if-env-changed=SOURCE_DATE_EPOCH");

    let pkg_version = env::var("CARGO_PKG_VERSION").unwrap_or_else(|_| "0.0.0".to_string());

    // Try to gather git info. Don't fail build if git is unavailable.
    let git_commit = Command::new("git")
        .args(["rev-parse", "--short", "HEAD"])
        .output()
        .ok()
        .and_then(|o| if o.status.success() { Some(String::from_utf8_lossy(&o.stdout).trim().to_string()) } else { None });

    let git_branch = Command::new("git")
        .args(["rev-parse", "--abbrev-ref", "HEAD"])
        .output()
        .ok()
        .and_then(|o| if o.status.success() { Some(String::from_utf8_lossy(&o.stdout).trim().to_string()) } else { None });

    let dirty = Command::new("git")
        .args(["status", "--porcelain"])
        .output()
        .ok()
        .map(|o| !String::from_utf8_lossy(&o.stdout).trim().is_empty())
        .unwrap_or(false);

    let mut version = format!("{}", pkg_version);
    if let Some(commit) = git_commit {
        if let Some(branch) = git_branch {
            version = format!("{} ({} @ {}{})", pkg_version, branch, commit, if dirty { "+" } else { "" });
        } else {
            version = format!("{} ({}{})", pkg_version, commit, if dirty { "+" } else { "" });
        }
    }

    // Expose as env var for the crate
    println!("cargo:rustc-env=LINUTIL_VERSION={}", version);
}

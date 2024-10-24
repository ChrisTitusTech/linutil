use chrono::{TimeZone, Utc};
use std::env;

fn main() {
    // Add current date as a variable to be displayed in the 'Linux Toolbox' text.
    let now = match env::var("SOURCE_DATE_EPOCH") {
        Ok(val) => { Utc.timestamp_opt(val.parse::<i64>().unwrap(), 0).unwrap() }
        Err(_) => Utc::now(),
    };
    println!(
        "cargo:rustc-env=BUILD_DATE={}",
        now.format("%Y-%m-%d")
    );
}

mod docgen;
mod path;

use std::{env, error::Error};

type DynError = Box<dyn Error>;

pub mod tasks {
    use crate::{
        docgen::{userguide, write, USER_GUIDE},
        DynError,
    };

    pub fn docgen() -> Result<(), DynError> {
        write(USER_GUIDE, &userguide()?);
        Ok(())
    }

    pub fn print_help() {
        println!(
            "
Usage: `cargo xtask <task>`

    Tasks:
        docgen: Generate Markdown files.
"
        );
    }
}

fn main() -> Result<(), DynError> {
    let task = env::args().nth(1);
    match task {
        None => tasks::print_help(),
        Some(t) => match t.as_str() {
            "docgen" => tasks::docgen()?,
            invalid => return Err(format!("Invalid task: {}", invalid).into()),
        },
    };
    Ok(())
}

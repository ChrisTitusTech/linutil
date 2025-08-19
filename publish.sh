#!/bin/bash

cargo build --release
cargo publish -p linutil_core
cargo publish -p linutil_tui

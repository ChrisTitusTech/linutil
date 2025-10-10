#!/bin/bash

cargo test --no-fail-fast --package linutil_core
cargo build --release
cargo publish -p linutil_core
cargo publish -p linutil_tui

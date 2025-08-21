# OpenCode Agent Guidelines for LinUtil

## Build/Test/Lint Commands
- **Build**: `cargo build --release`
- **Test**: `cargo test` 
- **Lint**: `cargo clippy -- -Dwarnings`
- **Format**: `cargo fmt --all` (fix) or `cargo fmt --all --check` (check)
- **Cross-compile**: `cross build --target=aarch64-unknown-linux-musl --release`
- **Shell Scripts**: `find core/tabs -name '*.sh' -exec shellcheck {} +`

## Code Style Guidelines

### Rust
- **Edition**: 2021 (workspace-level)
- **Imports**: Use `imports_granularity = "Crate"` per rustfmt.toml
- **Module Structure**: Use `mod modulename;` declarations at file top
- **Import Order**: std → external crates → local modules  
- **Error Handling**: Use `Result<T>` for fallible operations
- **Naming**: snake_case (functions/vars), PascalCase (types/structs)
- **Dependencies**: Check existing Cargo.toml before adding crates
- **Workspace**: Multi-crate (tui, core, xtask) - respect boundaries

### Shell Scripts
- **Shell**: bash (#!/bin/bash)
- **Linting**: Use shellcheck for all .sh files
- **Location**: Organize in `core/tabs/` by category
- **Style**: Follow existing script patterns in codebase

## Project Structure
- `tui/`: Terminal UI crate (main binary)
- `core/`: Core library and shell scripts
- `xtask/`: Build and development tools
- Shell utilities in `core/tabs/` categorized by function

## MCP Integration
OpenCode uses MCP servers defined in `.opencode/mcp-config.json` for:
- Rust language support via rust-analyzer
- Bash scripting support via bash-language-server
- Linting via cargo clippy and shellcheck
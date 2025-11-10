# Copilot instructions for linutil

This repo is a Rust workspace that builds a TUI app which runs curated shell scripts via a structured tab tree.
Crates:
- core (`linutil_core`): embeds and parses tab metadata/scripts, builds an in-memory tree of actions.
- tui (`linutil_tui`, bin `linutil`): ratatui UI, selection/search/multi-select, PTY-backed execution.
- xtask: helper tasks (docs generation).

## Architecture and data flow
- Assets are embedded at build time from `core/tabs/**` via `include_dir` and extracted at runtime to a temp dir.
- `core/src/inner.rs` parses TOML:
  - `core/tabs/tabs.toml` → list of tab folders; each folder contains `tab_data.toml`.
  - Entry types: directory (`entries`), raw command (`command`), script (`script`).
  - Optional `preconditions` gate entries: `environment`, `command_exists`, `file_exists`, `containing_file` with `matches` boolean (all must pass).
- Scripts: `get_shebang()` reads the first line; fallback is `/bin/sh -e` when missing. With validation (default), the shebang executable must exist and be executable; otherwise the entry is skipped. `--override-validation` disables this filter.
- UI builds state with `linutil_core::get_tabs(validate)`; commands run in a PTY (see `tui/src/running_command.rs`) with `TERM=xterm-256color` and truecolor env. After completion, press `l` to save logs.

## Conventions specific to this repo
- Editing `core/tabs/**` requires a rebuild (assets embedded). Ensure scripts are executable and have a correct shebang if you don’t want the `/bin/sh -e` default.
- Config lookups use leaf `name` values; keep command names unique across the tree to avoid ambiguity in `auto_execute`.
- Multi-select is inherited: a command is multi-selectable only if it and all ancestors have `multi_select = true`.
- Adding tabs: list new tab folders in `core/tabs/tabs.toml` under `directories = [ ... ]`, and provide a `tab_data.toml` in each folder.

## Developer workflows
- Run locally: `cargo run -p linutil_tui -- [args]` (bin name: `linutil`). Useful flags: `-y` skip confirm, `-u` override validation, `-s` size bypass, `-m` mouse.
- Tests: `linutil_core` contains unit tests. Run `cargo test -p linutil_core` (CI runs these on PRs).
- Lint/format: `cargo clippy -- -Dwarnings` and `cargo fmt --all --check` (both enforced in CI).
- Docs: `cargo xtask docgen` regenerates docs; CI fails if `docs/` changes are uncommitted.
- Packaging: end-user installers `start.sh`/`startdev.sh` download and exec the latest `linutil` binary (useful for smoke testing).

## Config-driven runs
Pass a TOML file via `--config` (see `tui/src/cli.rs`, `core/src/config.rs`):
- `auto_execute = ["Fastfetch", "Alacritty"]` (leaf names)
- `skip_confirmation = true|false`
- `size_bypass = true|false`
The TUI will auto-run those commands after optional confirmation.

## Pointers to key files
- Core types/parsing: `core/src/lib.rs`, `core/src/inner.rs`, `core/src/config.rs`
- UI/exec: `tui/src/state.rs`, `tui/src/running_command.rs`, `tui/src/cli.rs`
- Embedded assets and scripts: `core/tabs/**`

If any part (preconditions, shebang validation, or config lookup) needs more detail, say what to expand and we’ll refine this guide.

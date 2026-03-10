---
title: Architecture & Design
weight: 1
toc: true
---

This document describes how Linutil is structured internally — the crate layout, data model, TUI design, script execution pipeline, and the build tooling.

## Workspace Layout

Linutil is a Cargo workspace with three crates:

```
linutil/
├── core/       # linutil_core  — backend library
├── tui/        # linutil_tui   — binary (the TUI you run)
└── xtask/      # build tooling (cargo xtask docgen)
```

### `core/` — `linutil_core`

The library crate. Responsible for:

- Defining the data model (`Tab`, `ListNode`, `Command`)
- Parsing all `tab_data.toml` files and building the menu tree
- **Embedding all scripts into the binary at compile time** using `include_dir!`
- Extracting embedded scripts to a temp directory at runtime
- Evaluating preconditions to filter out scripts unsupported on the current system
- Parsing the user's TOML config file

### `tui/` — `linutil_tui`

The binary crate. Responsible for:

- Setting up the terminal (crossterm alternate screen, raw mode)
- Running the main event loop
- Rendering the entire TUI layout via `ratatui`
- Handling all keyboard and mouse input
- Launching scripts in a pseudo-terminal (PTY) via `portable-pty`
- Parsing CLI arguments via `clap`

### `xtask/`

Cargo's task runner extension. Run with:

```bash
cargo xtask docgen
```

This reads all `tab_data.toml` files and generates `docs/content/userguide/userguide.md` — the auto-generated walkthrough page. **Always run this after adding or editing a script entry.**

---

## Data Model

The menu is a tree of `ListNode` items, grouped into named `Tab`s.

### `Tab`

```rust
pub struct Tab {
    pub name: String,
    pub tree: Tree<Rc<ListNode>>,
}
```

Each `Tab` maps to one top-level category. The five built-in tabs are defined in `core/tabs/tabs.toml`:

```toml
directories = [
    "applications-setup",
    "gaming",
    "security",
    "system-setup",
    "utils"
]
```

### `ListNode`

```rust
pub struct ListNode {
    pub name: String,
    pub description: String,
    pub command: Command,
    pub task_list: String,
    pub multi_select: bool,
}
```

Every item in the TUI is a `ListNode`. A node is either a **directory** (has children, `command = Command::None`) or a **leaf command** (no children, has a runnable `command`).

### `Command`

```rust
pub enum Command {
    Raw(String),       // inline shell command
    LocalFile {        // shell script file
        executable: String,
        args: Vec<String>,
        file: PathBuf,
    },
    None,              // directory node
}
```

- `Raw` — a short command string run directly by the shell
- `LocalFile` — a script file whose interpreter is read from the shebang line (e.g. `#!/bin/bash`)
- `None` — marks a category/folder node

---

## Tab Data Format

Each tab is defined by a `tab_data.toml` file inside `core/tabs/<tab-name>/`. Example:

```toml
name = "Applications Setup"

[[data]]
name = "Communication Apps"

[[data.entries]]
name = "Discord"
description = "Discord is a versatile communication platform..."
script = "communication-apps/discord-setup.sh"
task_list = "I"

[[data.entries]]
name = "Some Inline Command"
description = "Runs a quick command"
command = "echo hello"
task_list = "MP"
```

### Entry Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Display name shown in the TUI |
| `description` | No | Shown in the description floating window (`d` key) |
| `script` | One of | Path to a shell script (relative to the tab directory) |
| `command` | One of | Inline shell command string |
| `entries` | One of | Nested sub-entries (makes this node a directory) |
| `task_list` | No | One or more flag codes shown next to the item name |
| `multi_select` | No | Whether this command can be queued in multi-select mode (default: `true`) |
| `preconditions` | No | Conditions that must pass for the entry to be shown |

### Task List Flags

Flags shown to the right of each command name, defined in `state.rs`:

| Flag | Meaning |
|------|---------|
| `D` | Disk modifications (privileged) |
| `FI` | Flatpak installation |
| `FM` | File modification |
| `I` | Installation (privileged) |
| `K` | Kernel modifications (privileged) |
| `MP` | Package manager actions |
| `SI` | Full system installation |
| `SS` | Systemd actions (privileged) |
| `RP` | Package removal |

---

## Preconditions

Preconditions let a script declare when it should be visible. If any precondition fails, the entry is hidden from the TUI.

```toml
[[data.entries]]
name = "Paru AUR Helper"
script = "paru-setup.sh"

[[data.entries.preconditions]]
matches = true
data = { containing_file = "/etc/os-release" }
values = ["Arch Linux", "Manjaro"]
```

### Precondition Types

| Type | Checks |
|------|--------|
| `environment` | Whether an environment variable equals one of the given values |
| `containing_file` | Whether a file's contents contain all of the given strings |
| `command_exists` | Whether a command is present on `$PATH` |
| `file_exists` | Whether a file path exists on disk |

The `matches` field inverts the check when `false` (i.e. "must NOT match").

---

## Script Embedding

All files under `core/tabs/` are embedded into the compiled binary at build time using the `include_dir!` macro:

```rust
const TAB_DATA: Dir = include_dir!("$CARGO_MANIFEST_DIR/tabs");
```

At runtime, `get_tabs()` extracts the embedded directory to a system temp directory (`/tmp/linutil_scripts_XXXX`), and all `LocalFile` commands reference scripts inside that temp dir. The temp directory is cleaned up automatically when `TabList` is dropped.

This means **a single binary contains everything** — no external script files needed after build.

---

## Script Execution Pipeline

When a user selects a command and confirms it:

1. `AppState::handle_confirm_command()` creates a `RunningCommand` from the list of selected `Command` values
2. `RunningCommand::new()` allocates a PTY via `portable-pty` (`NativePtySystem`)
3. The command is spawned inside the PTY as a child process
4. A **reader thread** reads output from the PTY master and writes it into a shared `Arc<Mutex<Vec<u8>>>` buffer
5. An **atomic flag** (`TERMINAL_UPDATED`) is set when new output arrives, triggering a TUI redraw
6. The PTY output is decoded by a `vt100` parser and rendered as a `PseudoTerminal` widget (from `tui-term`) inside a floating window
7. The user can scroll up/down to review output, or press `Ctrl-C` to kill the process
8. When the process exits, the floating window title changes to `SUCCESS` (green) or `FAILED` (red)

Using a real PTY (instead of piped stdio) means scripts that use terminal colors, interactive prompts, or check `isatty()` work correctly.

---

## TUI Layout

The TUI is rendered by `AppState::draw()` and divided into these regions:

```
┌──────────────┬────────────────────────────────┐
│   Logo /     │  [ Search bar                ] │
│   Version    ├────────────────────────────────┤
│              │                                │
│  Tab List    │   Item List                    │
│              │                                │
│  System Info │                                │
├──────────────┴────────────────────────────────┤
│   Keyboard hint bar                           │
└───────────────────────────────────────────────┘
```

- **Left column**: Logo (or version label), tab list, system info panel
- **Right column**: Search bar (top) + scrollable item list
- **Bottom bar**: Context-sensitive keyboard shortcut hints
- **Floating windows**: Overlaid on the item list for running commands, previews, descriptions, and confirmation prompts

### Focus State Machine

`AppState` tracks a `Focus` enum:

| State | Description |
|-------|-------------|
| `TabList` | User is navigating the left tab panel |
| `List` | User is navigating the item list |
| `Search` | The search bar is active |
| `FloatingWindow` | A modal is open (preview, description, running command, guide) |
| `ConfirmationPrompt` | User is being asked to confirm before running a command |

Input is dispatched to the currently focused component.

---

## Config File

Linutil reads an optional TOML config file at startup (`--config path`). The `linutil_core::Config` struct deserializes it:

```rust
pub struct Config {
    auto_execute: Option<Vec<String>>,
    skip_confirmation: Option<bool>,
    size_bypass: Option<bool>,
}
```

After parsing, `auto_execute` command names are looked up by name in the loaded `TabList` (using `Tab::find_command_by_name`), and the resulting `Vec<Rc<ListNode>>` is placed directly into `selected_commands` to be run immediately on startup.

---

## Adding a New Script

1. Create a shell script in `core/tabs/<tab-name>/<category>/your-script.sh`
2. Add an entry to the corresponding `tab_data.toml`:

```toml
[[data.entries]]
name = "Your Script"
description = "What it does."
script = "<category>/your-script.sh"
task_list = "I"
```

3. Add preconditions if the script is distro-specific
4. Run `cargo xtask docgen` to update the documentation
5. Run `cargo run` to test it locally

---

## Key Dependencies

| Crate | Purpose |
|-------|---------|
| `ratatui` | TUI rendering framework |
| `crossterm` | Cross-platform terminal control (raw mode, events) |
| `portable-pty` | Pseudo-terminal allocation for running commands |
| `tui-term` | PTY output rendering widget for ratatui |
| `vt100-ctt` | VT100 terminal emulator (parses ANSI escape codes) |
| `ego-tree` | Generic tree structure used for the menu |
| `include_dir` | Embed entire directory trees into the binary at compile time |
| `serde` + `toml` | Deserialize `tab_data.toml` and config files |
| `clap` | CLI argument parsing |
| `tree-sitter-bash` | Bash syntax highlighting in script previews |

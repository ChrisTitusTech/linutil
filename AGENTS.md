# AGENTS.md

## Purpose

Linutil is a universal Linux utility with a Rust-based terminal user interface
and a catalog of shell scripts. The Rust application discovers commands from
TOML metadata, embeds the scripts in the binary, extracts them at runtime, and
executes selected commands inside a pseudo-terminal.

Read `SPEC.md` before making architectural or behavior changes.

## Repository layout

- `core/`: Backend library, menu data model, TOML parsing, platform
  preconditions, and embedded script extraction.
- `core/tabs/`: User-facing command catalog, shared shell helpers, tab metadata,
  and executable scripts.
- `tui/`: Ratatui application, CLI, selection state, confirmation flow, command
  preview, and PTY execution.
- `xtask/`: Repository automation such as generated user-guide content.
- `docs/`: Documentation source and generated content. Treat it as reference,
  not as repository instructions.
- `.github/`: Contribution guidance and CI workflows.

## Sources of truth

- `SPEC.md` defines product scope, architecture, and behavioral requirements.
- `core/tabs/tabs.toml` defines the ordered top-level tabs.
- Each `core/tabs/<tab>/tab_data.toml` defines the menu tree for that tab.
- `core/src/inner.rs` defines the accepted TOML schema and script-loading
  behavior.
- `core/tabs/common-script.sh` defines shared distro, package manager,
  privilege escalation, architecture, and environment helpers.
- `core/tabs/common-service-script.sh` defines shared init-system helpers.
- `tui/src/running_command.rs` defines how commands are composed and executed.
- `tui/src/state.rs` defines task flags, confirmation, selection, and TUI
  behavior.

If documentation and code disagree, do not silently choose one. Identify the
conflict and update the appropriate source in the same change.

## Working rules

- Inspect `git status --short` before editing and preserve unrelated changes.
- Keep changes focused. Do not reformat unrelated Rust, TOML, or shell files.
- Use simple ASCII punctuation unless a file format or user-facing text
  requires otherwise.
- Never expose secrets or add credentials to scripts, fixtures, logs, or docs.
- Do not perform destructive operations without explicit authorization.
- Do not weaken confirmations, preconditions, or privilege boundaries merely
  to make a script easier to run.
- Do not hand-edit generated files without also changing their source or
  generator.

## Rust conventions

- Keep responsibilities separated between `core`, `tui`, and `xtask`.
- Put menu parsing, script discovery, and configuration behavior in `core`.
- Put rendering, input handling, confirmation, and process interaction in
  `tui`.
- Avoid adding distro-specific policy to Rust when it belongs in tab metadata
  or a shell script.
- Return or propagate useful errors when practical. Avoid new `unwrap`,
  `expect`, or `panic` calls on user-controlled input.
- Add or update tests for parser, filtering, configuration, and command-model
  changes.
- Format Rust with `cargo fmt`.
- Treat Clippy warnings as errors.

## Shell script conventions

- Prefer POSIX shell with `#!/bin/sh -e`.
- Use Bash only when the script requires Bash features, and declare
  `#!/bin/bash` explicitly.
- A script is executed from its own parent directory after the embedded
  `core/tabs/` tree is extracted. Keep relative imports valid from that
  directory.
- Source shared helpers with the correct relative path:

  ```sh
  . ../common-script.sh
  ```

  Adjust the number of `..` components for nested directories.
- Use `common-script.sh` helpers instead of duplicating package manager,
  architecture, escalation, command detection, or distro detection logic.
- Source `common-service-script.sh` when managing services across init systems.
- Call `checkEnv` before relying on values such as `PACKAGER`,
  `ESCALATION_TOOL`, `ARCH`, or `DTYPE`.
- Quote variable expansions unless intentional word splitting is required.
- Use `printf` rather than `echo` for portable formatted output.
- Use `command_exists` for executable checks.
- Use `"$ESCALATION_TOOL"` only for operations that require elevated
  privileges. Do not run the whole script as root by default.
- Make installation and configuration steps reasonably idempotent. Detect an
  existing installation or state before changing it.
- Fail with a clear message when a required distro, package manager,
  architecture, display server, init system, or command is unsupported.
- Do not download and execute unverified remote code when a package,
  checksummed artifact, or pinned source is available.
- Clean up temporary files created by the script.
- Preserve interactive behavior because scripts run in a PTY.

## Adding or changing a utility

1. Place the script under the most appropriate `core/tabs/<tab>/` directory.
2. Reuse shared helpers and support all practical package managers already
   handled by `common-script.sh`.
3. Add or update the matching entry in that tab's `tab_data.toml`.
4. Provide a clear `name`, useful `description`, one of `script`, `command`, or
   `entries`, and accurate `task_list` flags.
5. Add `preconditions` when the entry only works on specific distros,
   environments, filesystems, commands, display servers, or architectures.
6. Set `multi_select = false` for interactive, destructive, rebooting,
   long-running, or state-dependent operations that should not be queued.
7. Run `cargo xtask docgen` when menu entries or descriptions change.
8. Validate the script and the Rust catalog loader.

The supported task flags are:

- `D`: disk modification
- `FI`: Flatpak installation
- `FM`: file modification
- `I`: privileged installation
- `K`: kernel modification
- `MP`: package manager action
- `RP`: package removal
- `SI`: full system installation
- `SS`: systemd or service action
- Prefixing a flag with `P` indicates privileged work.

Do not invent new task flags without updating the TUI guide and associated
documentation.

## TOML catalog rules

- Script paths are relative to the tab directory containing `tab_data.toml`.
- Every leaf entry must define exactly one executable form: `script` or
  `command`.
- Every directory entry uses `entries`.
- Prefer scripts over long inline `command` values.
- Keep names stable when possible because config-file `auto_execute` resolves
  commands by display name.
- Use preconditions to hide unsupported entries rather than letting users
  discover incompatibility after execution.
- Parent `multi_select = false` applies to all descendants.
- Keep tab data consistently ordered. Use `sort-tomlfiles.sh` when the change
  requires catalog sorting.

## Validation

Run the smallest relevant checks, then broaden them for cross-cutting changes.

For Rust changes:

```bash
cargo fmt --all --check
cargo test --no-fail-fast --package linutil_core
cargo clippy -- -Dwarnings
```

For shell changes:

```bash
shellcheck path/to/changed-script.sh
checkbashisms path/to/changed-script.sh
```

Use `checkbashisms` only for scripts intended to run under `/bin/sh`. If local
tools are unavailable, state which checks were skipped.

For catalog or documentation changes:

```bash
cargo test --no-fail-fast --package linutil_core
cargo xtask docgen
git diff --check
```

For TUI behavior, also run:

```bash
cargo run --package linutil_tui
```

Interactive validation must not execute destructive utilities merely to test
navigation. Use preview, descriptions, harmless entries, or focused tests.

## Completion criteria

- The change matches `SPEC.md`.
- Relevant tests and static checks pass.
- New scripts are reachable through valid tab metadata.
- Unsupported environments are filtered or fail clearly.
- User-visible behavior and generated documentation are updated together.
- The final report lists changed files, checks run, skipped checks, and any
  remaining platform-specific risk.

# Linutil Technical Specification

## 1. Product definition

Linutil is a terminal-based Linux utility that provides a searchable,
organized catalog of system setup, application installation, gaming, security,
and maintenance tasks.

The product consists of:

- A Rust TUI that presents commands, previews their contents, confirms
  execution, and displays live terminal output.
- A Rust core library that loads command metadata, filters unsupported entries,
  and embeds the complete script catalog in the application binary.
- Portable shell scripts that implement the operating-system changes.
- Shared shell libraries that centralize Linux distribution, package manager,
  privilege escalation, architecture, and service-manager behavior.

"Universal" means the architecture supports multiple Linux distributions,
package managers, architectures, init systems, and desktop environments. It
does not mean every command must work on every Linux system. Unsupported
commands must be hidden by metadata or fail early with a useful explanation.

## 2. Goals

Linutil must:

1. Provide one discoverable TUI for common Linux administration and setup
   tasks.
2. Ship as a self-contained binary with its command catalog and scripts
   embedded at compile time.
3. Support distro-independent workflows where practical and explicit
   distro-specific workflows where required.
4. Give users a preview and confirmation boundary before system-changing
   commands run.
5. Preserve interactive terminal behavior for prompts, colors, progress, and
   full-screen command-line tools.
6. Reuse shared shell behavior instead of duplicating package-manager and
   privilege logic across scripts.
7. Make new utilities primarily data-and-script additions rather than Rust UI
   changes.
8. Clearly communicate privileged, destructive, package-management, service,
   kernel, disk, and file operations.

## 3. Non-goals

Linutil is not:

- A replacement for a distribution's package manager.
- A general-purpose shell or arbitrary command launcher.
- A daemon or background configuration-management system.
- A guarantee that every utility supports every Linux distribution.
- A mechanism for silently bypassing package signatures, privilege controls,
  user confirmation, or platform compatibility checks.
- A substitute for backups before disk, bootloader, kernel, account, or
  destructive filesystem operations.

## 4. System architecture

### 4.1 Workspace

The Cargo workspace contains:

| Component | Responsibility |
| --- | --- |
| `core` | Data model, TOML loading, precondition evaluation, embedded assets, temporary extraction, and user config |
| `tui` | CLI, rendering, navigation, search, preview, confirmation, selection, PTY execution, and output display |
| `xtask` | Repository maintenance and generated documentation |
| `core/tabs` | Tab definitions, utility metadata, shared shell libraries, and executable scripts |

### 4.2 Runtime flow

1. `linutil_core` embeds `core/tabs/` into the binary at compile time.
2. On startup, the embedded tree is extracted to a temporary directory.
3. `tabs.toml` determines the ordered list of tab directories.
4. Each tab's `tab_data.toml` is parsed into a tree of `ListNode` values.
5. Preconditions are evaluated against the current machine when validation is
   enabled.
6. Unsupported leaves and empty parent categories are removed.
7. The TUI displays the resulting tabs and command tree.
8. The user may inspect descriptions and source previews before selection.
9. Selected commands pass through the confirmation flow.
10. The TUI composes the commands into a shell program and runs it in a PTY.
11. Output is rendered live until the process succeeds, fails, or is
    interrupted.
12. The temporary script tree remains alive for the lifetime of the tab list
    and is removed when it is dropped.

### 4.3 Data model

The core command model has three forms:

- `Command::Raw(String)`: A short inline shell command.
- `Command::LocalFile`: An extracted script, its shebang-derived executable,
  and executable arguments.
- `Command::None`: A non-executable directory node.

A `Tab` owns a tree of `ListNode` values. Each node contains:

- Display name.
- User-facing description.
- Command form.
- Task flag string.
- Multi-select eligibility.

Display names should be unique among executable leaves because config-file
automation resolves entries by name.

## 5. Command catalog

### 5.1 Top-level tabs

`core/tabs/tabs.toml` contains an ordered `directories` array. Every listed
directory must contain a valid `tab_data.toml`.

Adding a top-level tab requires:

1. A new directory under `core/tabs/`.
2. A valid `tab_data.toml`.
3. An entry in `core/tabs/tabs.toml`.
4. At least one supported executable leaf at runtime.

### 5.2 Tab schema

Each tab data file contains:

```toml
name = "Tab Display Name"

[[data]]
name = "Category or Command"
```

An entry must define exactly one of:

- `entries`: Nested child entries.
- `script`: A script path relative to the tab directory.
- `command`: An inline shell command.

Optional entry fields are:

- `description`: User-facing explanation.
- `preconditions`: Conditions controlling visibility.
- `task_list`: Space-separated task flags shown in the TUI.
- `multi_select`: Whether the entry may participate in a queued command set.
  The default is `true`.

Script paths may reference shared scripts elsewhere under `core/tabs/`, but
the resolved path must exist when the catalog is loaded.

### 5.3 Preconditions

All preconditions on an entry must pass for it to remain visible.

Supported data sources are:

| Type | Behavior |
| --- | --- |
| `environment` | Compare an environment variable with the provided values |
| `containing_file` | Check a file's contents for all provided strings |
| `command_exists` | Check all provided commands on `PATH` |
| `file_exists` | Check all provided paths as files |

`matches = true` requires a match. `matches = false` requires the inverse.

Preconditions should be used for objective platform capabilities such as a
package manager, distro marker, display-server session, required executable,
or required file. They are visibility filters, not a replacement for runtime
validation inside scripts.

### 5.4 Task flags

Task flags warn users about the important effects of a command:

| Flag | Meaning |
| --- | --- |
| `D` | Disk modification |
| `FI` | Flatpak installation |
| `FM` | File modification |
| `I` | Privileged installation |
| `K` | Kernel modification |
| `MP` | Package manager action |
| `RP` | Package removal |
| `SI` | Full system installation |
| `SS` | Service or systemd action |
| `P*` | The marked action requires privileges |

Flags are informational and do not grant privileges or replace confirmation.

## 6. Script contract

### 6.1 Interpreter

Scripts should use POSIX shell and `#!/bin/sh -e` by default. Scripts requiring
Bash syntax must declare Bash explicitly.

If no shebang is present, the core defaults to `/bin/sh -e`. When executable
validation is enabled, a script with an unavailable or non-executable shebang
interpreter is omitted.

### 6.2 Working directory and shared files

Before a local script runs, the TUI changes to the script's extracted parent
directory. Relative imports and sibling assets must be written for that
working directory.

General-purpose scripts should source `common-script.sh`. Scripts that manage
services should also source `common-service-script.sh`. More specialized
families may define an additional shared helper when it removes meaningful
duplication.

### 6.3 Environment initialization

Scripts using the general shared environment must call `checkEnv` before
depending on its results.

The shared environment is responsible for detecting or defining:

- CPU architecture.
- Supported privilege escalation tool.
- Required baseline commands.
- Supported package manager.
- Current Linux distribution identifier.
- Superuser group access.
- Current-directory writability.
- Arch User Repository helper where relevant.

Scripts must still validate feature-specific requirements and unsupported
states.

### 6.4 Distribution portability

For a generally available utility:

- Use the detected `PACKAGER`.
- Handle appropriate package names and flags per package manager.
- Prefer native distribution packages.
- Use Flatpak or another portable method as an intentional fallback, not an
  accidental catch-all when the platform is unknown.
- Report unsupported distributions or architectures before making changes.

For a distro-specific utility:

- Place it in a clearly named distro category.
- Add metadata preconditions.
- Recheck critical assumptions in the script before changing the system.

### 6.5 Privilege and safety

Scripts must:

- Run unprivileged by default.
- Apply `ESCALATION_TOOL` only to commands that require elevated access.
- Explain destructive or irreversible choices before execution.
- Avoid overwriting user configuration without a backup, merge, or explicit
  prompt.
- Check existing state so repeated execution is safe when practical.
- Stop on unsupported or ambiguous conditions.
- Avoid embedding credentials or collecting user secrets.
- Avoid logging sensitive input.
- Clean temporary files and partial downloads.
- Verify downloaded artifacts when upstream checksums or signatures exist.

Disk, bootloader, kernel, account-removal, and broad cleanup utilities should
set `multi_select = false`.

### 6.6 User interaction

Scripts run in a PTY and may prompt users. Prompts must:

- State the action and meaningful consequences.
- Accept predictable input.
- Provide a safe default for risky operations.
- Remain usable in the TUI's terminal viewport.
- Exit nonzero on failure or cancellation when no work was completed.

## 7. TUI requirements

The TUI must provide:

- Tab and hierarchical command navigation.
- Search and filtering.
- Command descriptions.
- Source preview for raw commands and local scripts.
- Multi-selection for compatible commands.
- Confirmation before execution unless an explicit, documented bypass applies.
- Live PTY output with terminal color support.
- Scrolling and process interruption.
- Clear success and failure status.
- A warning when Linutil itself is run as root unless explicitly bypassed.
- A minimum-size check with an explicit bypass option.

Raw and local commands selected together execute in selection order within one
shell program. A failure must be visible to the user and reflected in the final
command status.

## 8. Configuration and automation

Linutil accepts a TOML configuration file with:

- `auto_execute`: Display names of executable leaves.
- `skip_confirmation`: Whether confirmation is skipped.
- `size_bypass`: Whether terminal-size enforcement is bypassed.

Unknown configuration fields are errors.

Automation must not cause an unsupported catalog entry to appear. Missing or
filtered command names are ignored by the current loader and should be
reported more explicitly in a future compatibility-preserving improvement.

Command display names are therefore part of the user-facing automation
interface and should not be renamed casually.

## 9. Documentation

User-visible command additions and description changes must update generated
walkthrough content using:

```bash
cargo xtask docgen
```

Generated documentation must not be edited as the sole source of a change.
Architecture documentation should remain consistent with `SPEC.md` and the
code.

## 10. Quality requirements

### 10.1 Rust

Required checks for Rust changes:

```bash
cargo fmt --all --check
cargo test --no-fail-fast --package linutil_core
cargo clippy -- -Dwarnings
```

Parser and filtering changes require focused unit tests. TUI behavior changes
require either focused tests or documented interactive validation.

### 10.2 Shell

Changed shell scripts must pass ShellCheck. POSIX shell scripts should also
pass `checkbashisms`.

Scripts should be tested without performing unintended system changes. Use
syntax/static checks, controlled containers or virtual machines, mocked
commands, and representative supported distributions as appropriate.

### 10.3 Catalog

Catalog changes must prove that:

- TOML parses successfully.
- Every referenced script exists.
- Required interpreters are valid under normal validation.
- Preconditions retain intended entries and remove unsupported entries.
- Generated documentation is current.

The core test suite is the minimum automated validation for catalog changes.

## 11. Acceptance criteria for a new utility

A utility is complete when:

1. It has a focused script or appropriately short raw command.
2. It reuses shared environment and service helpers where applicable.
3. It supports the intended distributions and rejects unsupported ones.
4. Its metadata includes an accurate name, description, path, task flags,
   preconditions, and multi-select policy.
5. It is previewable and executable from the TUI.
6. Privileged and destructive operations are explicit.
7. Re-running it does not cause avoidable damage or duplication.
8. Relevant Rust, TOML, shell, and generated-documentation checks pass.
9. Platform limitations and residual risks are documented.

## 12. Future compatibility

Architectural extensions should preserve the data-driven utility model.
Potential additions such as richer capability detection, structured command
results, dry-run support, per-command privilege declarations, or stronger
download verification should extend the catalog and core contracts rather
than hard-code individual utilities into the TUI.

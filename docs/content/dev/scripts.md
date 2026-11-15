---
title: Writing a Script
weight: 2
toc: true
---

This page covers what a new script needs to fit in with the rest of the catalog. For how scripts are loaded and run, see [Architecture & Design](../architecture/).

## Where Scripts Go

Scripts live under `core/tabs/<tab>/`, usually in a folder for their category, for example `core/tabs/applications-setup/pdf-suites/evince.sh`. A script only shows up in the TUI once it has an entry in that tab's `tab_data.toml`.

Each script runs from its own folder, so shared helpers are sourced with a relative path. Add one `..` for each folder level below `core/tabs/`:

```sh
. ../../common-script.sh
```

## A Basic Script

Most install scripts follow the same shape: source the helpers, define a function, call `checkEnv`, then call the function.

```sh
#!/bin/sh -e

. ../../common-script.sh

installEvince() {
    if ! command_exists evince; then
        printf "%b\n" "${YELLOW}Installing Evince...${RC}"
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm evince
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add evince
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy evince
                ;;
            apt-get|nala|zypper|dnf|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y evince
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Evince is already installed.${RC}"
    fi
}

checkEnv
installEvince
```

A few rules this follows:

- Use `#!/bin/sh -e` and POSIX shell. Only use `#!/bin/bash` when the script really needs Bash.
- Call `checkEnv` before using `PACKAGER`, `ESCALATION_TOOL`, `ARCH` or `DTYPE`.
- Only put `"$ESCALATION_TOOL"` in front of commands that need root. The script itself runs as the user.
- Check whether the work is already done before doing it, so running the script twice is safe.
- Use `printf` instead of `echo`, and quote variables.
- Stop with a clear message on anything unsupported instead of guessing.

## Shared Helpers

`core/tabs/common-script.sh` provides:

| Helper | Use |
|--------|-----|
| `checkEnv` | Detects the architecture, package manager, distro and escalation tool, and checks basic requirements |
| `command_exists` | Checks whether a command is on `PATH` |
| `checkFlatpak` | Makes sure Flatpak and Flathub are set up |
| `checkAURHelper` | Makes sure an AUR helper is available on Arch |
| `readMenuChoice` | Reads a menu choice so the TUI can handle `Esc` at action menus |
| `invalidChoice` | Exits with the status the TUI shows as `Invalid!` |
| `RED`, `YELLOW`, `GREEN`, `CYAN`, `RC` | Colours for output, `RC` resets |

Scripts that start, stop or enable services should also source `core/tabs/common-service-script.sh`, which has `startService`, `stopService`, `enableService`, `disableService`, `startAndEnableService` and `isServiceActive` for every supported init system.

## Adding the Catalog Entry

Add an entry to the tab's `tab_data.toml`. The `script` path is relative to the tab folder:

```toml
[[data.entries]]
name = "Evince"
description = "Evince is a document viewer for PDF and other formats."
script = "pdf-suites/evince.sh"
task_list = "I"
```

- Pick task flags that match what the script does. The flag list is on the [Architecture](../architecture/#task-list-flags) page.
- Set `multi_select = false` for anything interactive, destructive, long-running or that reboots, so it can't be queued with other commands.
- Try not to rename existing entries. [Automation](../../userguide/automation/) configs refer to commands by name.

## Preconditions

Preconditions hide an entry on systems where it can't work. Every precondition on an entry has to pass for it to show up, and `matches = false` flips the check.

The header follows where the entry sits in `tab_data.toml`. `[[data.preconditions]]` applies to a top-level item and everything inside it, while `[[data.entries.preconditions]]` applies to one entry inside a folder. The examples below use the entry form.

Only show the entry when `pacman` is available:

```toml
[[data.entries.preconditions]]
matches = true
data = "command_exists"
values = ["pacman"]
```

Hide the entry on Alpine:

```toml
[[data.entries.preconditions]]
matches = false
data = "command_exists"
values = ["apk"]
```

Only show the entry in a Wayland session:

```toml
[[data.entries.preconditions]]
matches = true
data = { environment = "XDG_SESSION_TYPE" }
values = ["wayland", "Wayland"]
```

The other two types are `{ containing_file = "/path" }`, which checks the file contains all of `values`, and `"file_exists"`, which checks every path in `values` exists.

Preconditions only control what is shown. The script should still check anything it depends on before it changes the system.

## Before Opening a Pull Request

```bash
shellcheck path/to/your-script.sh
checkbashisms path/to/your-script.sh   # only for #!/bin/sh scripts
cargo test --no-fail-fast --package linutil_core
cargo xtask docgen
```

`cargo xtask docgen` updates the [Walkthrough](../../userguide/walkthrough/). Commit the result together with your script.

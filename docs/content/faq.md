---
title: Frequently Asked Questions
toc: true
---

## General

### What is Linutil?

Linutil is Chris Titus Tech's Linux Utility — a distro-agnostic TUI toolbox built in Rust for installing apps, configuring your system, and running common Linux setup tasks.

### Is Linutil safe to use?

Yes. All scripts are open source and available on [GitHub](https://github.com/ChrisTitusTech/linutil). You can inspect any script before running it. However, always review what a script does before executing it, as some scripts make significant system changes.

### What Linux distributions does Linutil support?

Linutil is distro-agnostic. Most scripts work with any of these package managers:

| Package manager | Distros |
|-----------------|---------|
| `apt-get` / `nala` | Debian, Ubuntu and derivatives |
| `dnf` | Fedora and RHEL-based distros |
| `pacman` | Arch and derivatives |
| `zypper` | openSUSE |
| `apk` | Alpine |
| `xbps-install` | Void |
| `eopkg` | Solus |

Some scripts are distro-specific (Arch, Fedora, Debian, Ubuntu, Alpine) and are hidden on systems they don't support. The Debian and Ubuntu folders check `/etc/os-release`. The Arch, Fedora and Alpine folders check for `pacman`, `dnf` or `apk`, so they also show up on other distros that use that package manager. Linutil runs on x86_64 and aarch64.

### Does Linutil require root/sudo?

Linutil itself does not require root to launch. Individual scripts that make system-level changes will prompt for `sudo` when needed.

---

## Running Linutil

### How do I run Linutil?

```bash
curl -fsSL https://christitus.com/linux | sh
```

With Nix flakes, you can also run it without installing anything:

```bash
nix run github:ChrisTitusTech/linutil
```

### What's the difference between the stable and dev branch?

- **Stable** (`https://christitus.com/linux`) — Tested, recommended for daily use
- **Dev** (`https://christitus.com/linuxdev`) — Latest commits, may be unstable

### Can I install Linutil permanently?

Yes. It's available via:
- **AUR** (Arch): `paru -S linutil` or `paru -S linutil-bin`
- **openSUSE**: `sudo zypper install linutil`
- **Cargo**: `cargo install linutil_tui`

### The TUI won't open — it says my terminal is too small

Resize your terminal window to be larger, or bypass the size check:

```bash
curl -fsSL https://christitus.com/linux | sh -s -- --size-bypass
```

---

## Scripts & Features

### How do I find a specific script in the TUI?

Press `/` while in the TUI to open the search filter and type part of the script name.

### Can I run scripts without the interactive TUI?

Yes, using a TOML config file with `auto_execute`. See the [Automation guide](userguide/automation/) for details.

### A script failed — what should I do?

1. Check the error output shown in the terminal
2. Make sure your system is fully updated before running scripts
3. Search [GitHub Issues](https://github.com/ChrisTitusTech/linutil/issues) for the same error
4. Open a new issue if it hasn't been reported

### Can I undo changes made by a script?

This depends on the script. Some changes (like installing packages) can be reversed manually. For major system changes, it's good practice to have backups or snapshots beforehand (e.g., using Btrfs + Snapper on Fedora).

---

## Contributing

### How can I contribute?

See the [Contributing Guide](contributing/) for full details. In short:

1. Fork and clone the repo
2. Make your changes (scripts go in the appropriate `core/tabs/` subdirectory)
3. Test with `cargo run`
4. Submit a pull request

### How do I add a new script?

Fill out all fields in `tab_data.toml` for your script, then run `cargo xtask docgen` to regenerate the documentation. See the [Contributing Guide](contributing/) for more.

### Where do I report bugs?

Open an issue on [GitHub](https://github.com/ChrisTitusTech/linutil/issues). Include your distro, terminal, and any relevant error output.

---

## Updates

### How do I update Linutil?

- **Curl method**: Just re-run `curl -fsSL https://christitus.com/linux | sh` — it always fetches the latest
- **Cargo**: Use the built-in **Linutil Updater** script, or run `cargo install --force linutil_tui`
- **AUR**: `paru -Syu linutil`
- **openSUSE**: `sudo zypper update linutil`

### How do I check what version I'm running?

The version is shown under the logo in the TUI, as `Linutil v<version>`.

### Where can I see release notes?

On the [GitHub Releases page](https://github.com/ChrisTitusTech/linutil/releases).

---
title: Known Issues
toc: true
---

This page tracks known issues and limitations in Linutil. If you encounter a bug not listed here, please [open an issue on GitHub](https://github.com/ChrisTitusTech/linutil/issues).

## Terminal Compatibility

### Minimum Terminal Size

Linutil requires a minimum terminal size to display the TUI correctly. If your terminal is too small, you will see a warning and the TUI will not load.

**Workaround**: Resize your terminal to be larger, or use the `--size-bypass` flag:

```bash
curl -fsSL https://christitus.com/linux | sh -s -- --size-bypass
```

### Rendering Issues in Some Terminals

The TUI is built with `ratatui` and tested against common terminals (Alacritty, Kitty, GNOME Terminal, Konsole, etc.). Older or minimalist terminals may have rendering issues with box-drawing characters.

**Workaround**: Use a modern terminal emulator.

## Script-Specific Issues

### Scripts May Fail on Unsupported Distros

Some scripts are written for a specific distribution (e.g., Arch, Fedora). Running them on an unsupported distro may fail or produce unexpected results.

**Workaround**: Only run scripts listed under your distro's section in **System Setup**, or scripts that are explicitly distro-agnostic.

### Nvidia Driver Scripts Require Manual Steps on Some Systems

The Nvidia driver installation scripts may not cover every hardware configuration. Secure Boot, older GPUs, or custom kernel setups can cause driver installation to fail.

**Workaround**: Refer to your distro's official Nvidia documentation for manual installation if the script fails.

### Cargo Installs Require Manual Updates

If you installed Linutil via `cargo install linutil_tui`, updates are not automatic.

**Workaround**: Use the built-in **Linutil Updater** script inside the TUI, or run:

```bash
cargo install --force linutil_tui
```

## Active Development

Linutil is under active development. Since scripts are contributed by the community and updated frequently, some scripts may:

- Lag behind upstream package name changes
- Temporarily break after a distro update changes a package or dependency
- Not yet cover all edge cases for every distro version

**Workaround**: Check [open issues](https://github.com/ChrisTitusTech/linutil/issues) and [recent pull requests](https://github.com/ChrisTitusTech/linutil/pulls) for known fixes. Running the stable curl command always fetches the latest release:

```bash
curl -fsSL https://christitus.com/linux | sh
```

## Reporting Bugs

When opening a bug report, please include:

- Your Linux distribution and version
- Terminal emulator being used
- The exact script or menu item that failed
- The full error output from the terminal
- Steps to reproduce the issue

[Open an issue on GitHub →](https://github.com/ChrisTitusTech/linutil/issues/new)

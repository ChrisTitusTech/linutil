---
title: Getting Started with Linutil
weight: 1
---

## Welcome to Linutil!

Linutil is a distro-agnostic Linux toolbox built in Rust. It provides an interactive terminal UI (TUI) for installing applications, configuring your system, and running common Linux setup tasks — all from one place.

## System Requirements

Before running Linutil, ensure your system meets these requirements:

- **Operating System**: Any modern Linux distribution (Arch, Fedora, Debian, Ubuntu, openSUSE, etc.)
- **Shell**: Bash or a compatible POSIX shell
- **Internet Connection**: Required for downloading applications and scripts
- **curl**: Pre-installed on most distributions

## Running Linutil

Linutil runs directly from a single curl command — no installation required.

### Stable Branch (Recommended)

```bash
curl -fsSL https://christitus.com/linux | sh
```

### Dev Branch (Latest Features)

```bash
curl -fsSL https://christitus.com/linuxdev | sh
```

> [!NOTE]
> The dev branch may contain untested features. Use the stable branch for day-to-day use.

## Installing Linutil Locally

If you prefer a persistent local install, Linutil is available through several package managers.

### Arch Linux (AUR)

```bash
# Using paru
paru -S linutil

# Using yay
yay -S linutil

# Stable pre-compiled binary
paru -S linutil-bin
```

### openSUSE

```bash
sudo zypper install linutil
```

### Cargo

```bash
cargo install linutil_tui
```

> [!NOTE]
> Cargo installs require manual updates via `cargo install --force linutil_tui`, or use the built-in **Linutil Updater** script inside the tool.

## CLI Arguments

View all available options:

```bash
linutil --help
```

### Common Options

| Flag | Description |
|------|-------------|
| `--config` / `-c` | Path to a TOML config file |
| `--skip-confirmation` | Skip confirmation prompts |
| `--size-bypass` | Bypass terminal size requirements |

## Navigating the TUI

Once Linutil launches, you'll see a tree-style menu on the left and a description panel on the right.

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `↑` / `↓` or `j` / `k` | Move up/down in the list |
| `Enter` or `→` | Select / expand item |
| `←` | Collapse / go back |
| `Space` | Multi-select an item |
| `/` | Search/filter items |
| `q` or `Escape` | Quit / go back |
| `t` | Toggle multi-select mode |

### Menu Structure

Linutil is organized into these main categories:

- **Applications Setup** — Install popular Linux software
- **Gaming** — Gaming dependencies, emulators, game configs
- **Security** — Firewall setup and hardening
- **System Setup** — Distro-specific configuration (Arch, Fedora, Debian, Ubuntu, etc.)
- **Utilities** — Monitor control, printers, Bluetooth, WiFi, and more

## Your First Steps

Here are recommended actions for new users:

### 1. Browse and Install Applications

1. Navigate to **Applications Setup**
2. Browse categories (browsers, developer tools, communication apps, etc.)
3. Select an application and press `Enter` to run the install script

### 2. Set Up Your Distro

1. Navigate to **System Setup**
2. Find your distribution (Arch, Fedora, Debian, Ubuntu)
3. Run distro-specific scripts like AUR helpers, RPM Fusion, or package updates

### 3. Configure Utilities

1. Navigate to **Utilities**
2. Set up monitors, manage Bluetooth/WiFi, or configure services

## Troubleshooting First Run

### Script Won't Download

If the curl command fails, check your internet connection or try:

```bash
curl -fsSL https://raw.githubusercontent.com/ChrisTitusTech/linutil/main/linutil.sh | sh
```

### Permission Errors

Most scripts require sudo access. Linutil will prompt for your password when needed.

### Terminal Size Warning

If you get a terminal size warning, resize your terminal to be larger, or use the `--size-bypass` flag:

```bash
curl -fsSL https://christitus.com/linux | sh -s -- --size-bypass
```

## Next Steps

- [Application Setup](../store/) — Learn about installing software
- [System Setup](../tweaks/) — Distro-specific configuration
- [Features & Utilities](../features/) — Security, gaming, and utilities
- [Automation](../automation/) — Run Linutil with a config file
- [FAQ](../../faq/) — Common questions and answers

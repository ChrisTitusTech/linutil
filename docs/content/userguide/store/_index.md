---
title: Application Setup
weight: 2
---

The **Applications Setup** section of Linutil lets you install popular Linux software through pre-written install scripts. Each script handles package manager differences across distros automatically.

## Finding Applications

Use the search feature to quickly find what you need:

- Press `/` while in the TUI to open the search/filter
- Type part of the application name
- The list filters in real time

## Installing an Application

1. Navigate to **Applications Setup** in the main menu
2. Browse categories or search for the app you want
3. Select the application and press `Enter`
4. Linutil will run the install script — you may be prompted for your `sudo` password

## Application Categories

### Communication Apps

| App | Description |
|-----|-------------|
| Discord | Voice, video, and text chat for communities |
| Signal | End-to-end encrypted messaging |
| Slack | Team collaboration platform |
| Telegram | Fast, cloud-based messaging |
| Thunderbird | Open-source email client |
| Zoom | Video conferencing |

### Developer Tools

| App | Description |
|-----|-------------|
| VS Code | Lightweight code editor by Microsoft |
| VS Codium | VS Code without Microsoft telemetry |
| Cursor | AI-powered code editor |
| Neovim | CTT's configured Neovim setup |
| Zed | High-performance code editor written in Rust |
| GitHub Desktop | GUI for Git and GitHub |
| Docker | Container platform |
| Podman | Daemonless container engine |

### Web Browsers

| App | Description |
|-----|-------------|
| Firefox | Open-source browser by Mozilla |
| Brave | Privacy-focused Chromium browser |
| LibreWolf | Privacy-hardened Firefox fork |
| Chromium | Open-source base for Chrome |
| Zen Browser | Privacy-focused browser |
| Tor Browser | Anonymity browser via Tor network |

### Design Tools

| App | Description |
|-----|-------------|
| GIMP | Full-featured raster image editor |
| Inkscape | Vector graphics editor |
| Krita | Digital painting and 2D animation |
| Blender | 3D modeling and animation |
| OBS Studio | Screen recording and live streaming |
| Kdenlive | Non-linear video editor |

### Terminal & Shell

| App | Description |
|-----|-------------|
| Alacritty | GPU-accelerated terminal emulator |
| Kitty | Feature-rich GPU terminal emulator |
| Ghostty | Highly customizable terminal |
| Bash Prompt | CTT's `.bashrc` configuration |
| ZSH Prompt | ZSH shell with basic configuration |

### Other Notable Apps

| App | Description |
|-----|-------------|
| Fastfetch | System info display tool |
| Flatpak / Flathub | Universal Linux app sandbox |
| Bottles | Run Windows apps on Linux |
| Waydroid | Run Android apps on Linux |
| DWM-Titus | CTT's configured DWM window manager with install/uninstall menu and post-install session setup |
| Rofi | App launcher and window switcher |
| Auto CPU Frequency | Automatic CPU power optimizer |

## Updating Linutil Itself

Two scripts in Applications Setup manage Linutil's own lifecycle:

- **Linutil Installer** — Installs a distro-specific Linutil package locally
- **Linutil Updater** — Updates your local Linutil crate installation

> [!TIP]
> If you installed Linutil via `cargo install linutil_tui`, use the **Linutil Updater** script to keep it current instead of running `cargo install --force` manually.

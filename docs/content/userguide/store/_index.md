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

| Category | What's in it |
|----------|--------------|
| Communication Apps | Chat, email and video calling |
| Design Tools | Image, audio, video and 3D editors |
| Developer Tools | Code editors and Git tools |
| Office Suites | Office suites |
| PDF Suites | PDF viewers and editors |
| Web Browsers | Graphical and text-based browsers |

The rest of the tab covers terminals, shell prompts, desktop shells, containers, Flatpak, and Linutil itself.

For every app and what it does, see the [Walkthrough](../walkthrough/#applications-setup). It's generated from the script catalog, so it lists everything Linutil ships.

## Updating Linutil Itself

Two scripts in Applications Setup manage Linutil's own lifecycle:

- **Linutil Installer** — Installs a distro-specific Linutil package locally
- **Linutil Updater** — Updates your local Linutil crate installation

> [!TIP]
> If you installed Linutil via `cargo install linutil_tui`, use the **Linutil Updater** script to keep it current instead of running `cargo install --force` manually.

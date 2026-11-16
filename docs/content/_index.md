---
title: Linutil Documentation
description: Chris Titus Tech's Linux Utility - install apps, set up your distro, harden security, and run common Linux tasks from one terminal UI.
hero:
  title: Set up any Linux distro from one terminal
  tagline: Linutil is a menu of setup scripts that works across distros. Pick what you want, read the script first if you like, and it runs the right commands for your system.
  command: curl -fsSL https://christitus.com/linux | sh
facts:
  - key: runs on
    value: Arch, Fedora, Debian, Ubuntu, openSUSE, Alpine, Void, Solus
  - key: cpu
    value: x86_64, aarch64
  - key: install
    value: none needed
badges:
  - src: https://img.shields.io/github/v/release/ChrisTitusTech/linutil?style=flat-square&label=release&labelColor=30333d&color=55adff
    alt: Latest release
    link: https://github.com/ChrisTitusTech/linutil/releases/latest
  - src: https://img.shields.io/github/downloads/ChrisTitusTech/linutil/linutil?style=flat-square&label=downloads&labelColor=30333d&color=73daca
    alt: Total downloads
  - src: https://dcbadge.limes.pink/api/server/https://discord.gg/RUbZUZyByQ?style=flat
    alt: Discord community server
    link: https://discord.gg/RUbZUZyByQ
# Quick Help lists the keys the menu preview answers to. The flag legend is the TUI's, from tui/src/dashboard.rs.
keys:
  - key: k/j/up/down
    text: Move selection
  - key: enter/right
    text: Open
  - key: h/left/esc
    text: Parent directory
  - key: 1-5
    text: Switch category
flags:
  - key: D
    text: Disk modifications
  - key: FI
    text: Flatpak installation
  - key: FM
    text: File modification
  - key: I
    text: Privileged installation
  - key: K
    text: Kernel modifications
  - key: MP
    text: Package manager actions
  - key: SI
    text: Full system installation
  - key: SS
    text: Systemd actions
  - key: RP
    text: Package removal
  - key: P
    text: Privileged prefix (e.g. PFM)
catalog:
  title: What's in the menu
  text: Five categories, read from the same catalog files the TUI loads. Entries that need a particular distro, package manager, or display server only show up on systems that can run them.
  tabs:
    applications-setup: Browsers, terminals, developer tools, office suites, and desktop shells, installed with your own package manager.
    gaming: Gaming dependencies, Proton tools, game launchers, and emulators.
    security: Firewall baselines for UFW and FirewallD, plus security audits.
    system-setup: Distro-specific setup for Arch, Fedora, Debian, Ubuntu, and Alpine, and desktop environment installers.
    utils: Monitors, printers, Bluetooth, WiFi, user accounts, services, and local AI tools.
safety:
  title: Nothing runs until you say so
  text: Every entry is a plain shell script in the repository. Linutil gives you a few ways to check one before it touches your system.
  keys:
    - key: p
      text: Preview the exact script an entry will run.
    - key: d
      text: Read what a command does.
    - key: v
      text: Pick several commands and run them as one batch.
    - key: y / n
      text: Confirm or cancel. Linutil lists the commands you picked and waits.
install:
  title: Run it, or install it
  text: The one-liner downloads the latest release each time, so there's nothing to keep up to date. If you'd rather have it installed, it's packaged too.
  rows:
    - label: stable
      command: curl -fsSL https://christitus.com/linux | sh
    - label: dev
      command: curl -fsSL https://christitus.com/linuxdev | sh
    - label: aur
      command: paru -S linutil
    - label: opensuse
      command: sudo zypper install linutil
    - label: cargo
      command: cargo install linutil_tui
    - label: nix
      command: nix run github:ChrisTitusTech/linutil
automation:
  title: Same setup on every machine
  text: List the scripts you want in a TOML file and Linutil runs them on launch. Add skip_confirmation for a fully unattended run.
  file: config.toml
  config: |
    auto_execute = [
        "Fastfetch",
        "Alacritty",
        "Docker",
        "UFW Firewall Baselines (CTT)"
    ]

    skip_confirmation = true
  command: linutil --config config.toml
cta:
  title: Try it on your machine
  text: It opens a menu and waits. Nothing changes until you pick something and confirm it.
---

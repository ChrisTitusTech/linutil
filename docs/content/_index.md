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
# Linutil's own key list and flag legend, as the TUI shows them in its Quick Help and Flags panels.
keys:
  - key: k/j/up/down
    text: Move selection
  - key: enter/right
    text: Open/run
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
---

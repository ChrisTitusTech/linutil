---
title: System Setup
weight: 3
---

The **System Setup** section contains distro-specific and general configuration scripts to get your Linux system set up quickly. These scripts handle driver installation, package manager configuration, desktop environments, and more.

## Distro-Specific Setup

There are folders for Arch, Fedora, Debian, Ubuntu and Alpine, with scripts that only make sense on that distro, such as AUR helpers and extra repositories on Arch, or RPM Fusion and release upgrades on Fedora. Each folder is hidden on systems it doesn't support. The Arch, Fedora and Alpine folders show up wherever `pacman`, `dnf` or `apk` is installed, which includes distros based on them, while the Debian and Ubuntu folders check `/etc/os-release`.

## Desktop Environment Setup

These scripts work across distros and let you install or uninstall full desktop environments and window managers interactively.

### Install Desktop Environment

An interactive menu lets you choose from:

**Desktop Environments**: GNOME, KDE Plasma, XFCE, Cinnamon, MATE, Budgie, LXQt, LXDE

**Window Managers**: i3, Sway, DWM, Awesome, BSPWM, Openbox, Fluxbox

### Uninstall Desktop Environment

The reverse operation — interactively select which DE or WM to remove.

## General System Scripts

Scripts outside the distro folders aren't tied to one distro. They cover system updates and cleanup, audio, swap, SSD trim, fonts and theming.

For every script in this section and what it does, see the [Walkthrough](../walkthrough/#system-setup).

> [!TIP]
> Always run a **Full System Update** before installing new software or applying major configuration changes.

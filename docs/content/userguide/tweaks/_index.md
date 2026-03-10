---
title: System Setup
weight: 3
---

The **System Setup** section contains distro-specific and general configuration scripts to get your Linux system set up quickly. These scripts handle driver installation, package manager configuration, desktop environments, and more.

## Distro-Specific Setup

### Arch Linux

| Script | Description |
|--------|-------------|
| Arch Server Setup | Minimal Arch server install in under 5 minutes |
| Hyprland (JaKooLit) | Install JaKooLit's Hyprland configuration |
| Paru AUR Helper | Install the `paru` AUR helper |
| Yay AUR Helper | Install the `yay` AUR helper |
| Install Chaotic-AUR | Add the Chaotic-AUR repo for prebuilt AUR packages |
| Nvidia Drivers + HW Accel | Install and configure Nvidia drivers with hardware acceleration |
| Omarchy Rice by DHH | Simplified Hyprland config by DHH |
| Linux Neptune (SteamDeck) | Valve's fork of the Linux kernel for Steam Deck |
| Virtualization | Install QEMU, Libvirt, and Virt-Manager |

### Fedora

| Script | Description |
|--------|-------------|
| Configure DNF | Optimize DNF for parallel downloads |
| RPM Fusion | Add RPM Fusion free and non-free repositories |
| Multimedia Codecs | Install multimedia codecs with RPM Fusion |
| Nvidia Proprietary Drivers | Install proprietary Nvidia drivers |
| Hyprland (JaKooLit) | Install JaKooLit's Hyprland configuration |
| Virtualization | Enable virtualization via DNF |
| Btrfs Assistant + Snapper | Btrfs snapshots with grub-btrfs integration |
| Upgrade Fedora Release | Upgrade system to the next Fedora release |

### Debian

| Script | Description |
|--------|-------------|
| Hyprland (JaKooLit) | Install JaKooLit's Hyprland configuration |

### Ubuntu

| Script | Description |
|--------|-------------|
| Hyprland (JaKooLit) | Install JaKooLit's Hyprland configuration |
| Full System Cleanup | Remove unused packages, clear cache, empty trash |
| Full System Update | Update all packages to the latest available |
| Gaming Dependencies | Install gaming dependencies across distros |
| Global Theme | Install and configure a global desktop theme |
| Remove Snaps | Remove Snap and prevent it from reinstalling |
| Build Prerequisites | Install software build dependencies |
| TTY Fonts | Set the default TTY font to Terminus 32 Bold |

### Alpine

| Script | Description |
|--------|-------------|
| Alpine Update | Upgrade Alpine to the latest stable or edge release |

## Desktop Environment Setup

These scripts work across distros and let you install or uninstall full desktop environments and window managers interactively.

### Install Desktop Environment

An interactive menu lets you choose from:

**Desktop Environments**: GNOME, KDE Plasma, XFCE, Cinnamon, MATE, Budgie, LXQt, LXDE

**Window Managers**: i3, Sway, DWM, Awesome, BSPWM, Openbox, Fluxbox

### Uninstall Desktop Environment

The reverse operation — interactively select which DE or WM to remove.

## General System Scripts

These scripts work across all distributions:

| Script | Description |
|--------|-------------|
| Full System Update | Update all packages using your distro's package manager |
| Full System Cleanup | Clear package caches, temp files, and trash |
| Gaming Dependencies | Install dependencies needed for gaming on Linux |
| Build Prerequisites | Install common software build dependencies |

> [!TIP]
> Always run a **Full System Update** before installing new software or applying major configuration changes.

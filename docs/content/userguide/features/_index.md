---
title: Features & Utilities
weight: 4
---

Beyond application installation and system setup, Linutil includes categories for security hardening, gaming, and a wide range of system utilities.

## Security

Apply firewall baselines to protect your Linux system. Based on CTT's recommended security rules — for more detail see [christitus.com/linux-security-mistakes](https://christitus.com/linux-security-mistakes).

### UFW Firewall Baselines

UFW (Uncomplicated Firewall) is a user-friendly frontend for `iptables`. This script:

- Installs UFW if not present
- Applies CTT's recommended baseline rules for IPv4 and IPv6
- Enables the firewall

```bash
# Check UFW status after running the script
sudo ufw status verbose
```

### FirewallD Baselines

An alternative to UFW, FirewallD is the default firewall manager on Fedora and RHEL-based systems. This script configures FirewallD with CTT's recommended rules.

### Security Audits

**Lynis** and **rkhunter** run a system security audit and a rootkit scan. Each installs its tool if needed and offers to remove it again afterwards.

## Gaming

### Gaming Dependencies

Installs the libraries and tools needed to run games on Linux across different distributions, such as Wine, Vulkan support, MangoHud, GameMode, and related runtime dependencies. Steam and Lutris are managed separately from the **Game Launchers** section.

### Proton Compatibility Tools

The Gaming tab includes **ProtonPlus** and **ProtonUp-Qt** under **Tools and Setups**. Both tools use native packages where available, with Flathub Flatpak packages as a fallback:

| Tool | Flatpak ID |
|------|------------|
| ProtonPlus | `com.vysp3r.ProtonPlus` |
| ProtonUp-Qt | `net.davidotek.pupgui2` |

### Game Launchers

The Gaming tab includes a **Game Launchers** section for installing common game launchers.

| Launcher | Behavior |
|----------|----------|
| Steam | Uses native packages on Arch-based systems; uses Flatpak on several other distros where native availability is less consistent |
| Lutris | Uses the native package manager on supported distros |
| RetroArch | Uses native packages where available, with Flatpak fallback for selected distros |
| Heroic | Uses Flatpak on non-Arch systems; on Arch-based systems builds `heroic-games-launcher-bin` directly from AUR |

On NixOS, these entries print declarative configuration guidance instead of modifying the system imperatively.

### Emulators

Emulators are grouped by console maker: multi-system (RetroArch), Nintendo, PlayStation, Sega and Xbox.

> [!NOTE]
> No game ROMs or BIOS files are included. You must supply your own legally obtained files.

### Game-Specific Configs

**Tools and Setups** also has config files and mods for a few specific games. See the [Walkthrough](../walkthrough/#tools-and-setups) for the current list.

## Utilities

The Utilities tab covers monitor control (resolution, scaling, brightness, arrangement), printer drivers, and managers for Bluetooth, WiFi, services, locales and local AI models.

For every script and what it does, see the [Walkthrough](../walkthrough/#utilities).

## Themes

Press `t` to switch between the dark themes: Linutil, Nord, Tokyo Night, One Dark, Monochrome, Lucent-Orng, GitHub, Material and Flexoki. Linutil starts with the Linutil theme each time. To start with another one, use `--theme`, for example `linutil --theme tokyo-night`.

Themes need a truecolor terminal. On the Linux console and other terminals with fewer colours, Linutil keeps its basic colours and `t` shows a short note. If your terminal cannot draw the normal logo, `--theme compatible` selects the plain logo and basic colours.

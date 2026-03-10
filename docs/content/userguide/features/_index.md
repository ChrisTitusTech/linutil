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

## Gaming

### Gaming Dependencies

Installs the libraries and tools needed to run games on Linux across different distributions (Steam, Wine, DXVK, Vulkan drivers, etc.).

### Emulators

| Emulator | Console |
|----------|---------|
| RetroArch | Multi-system frontend |
| Dolphin | GameCube / Wii |
| PCSX2 | PlayStation 2 |
| RPCS3 | PlayStation 3 |
| Ryujinx | Nintendo Switch |
| mGBA | Game Boy Advance |
| MelonDS | Nintendo DS / DSi |
| bsnes / snes9x | Super Nintendo |
| Mupen64Plus / Gopher64 | Nintendo 64 |
| Flycast | Sega Dreamcast |
| Kronos | Sega Saturn |
| XEMU | Original Xbox |
| Blastem | Sega Genesis |

> [!NOTE]
> No game ROMs or BIOS files are included. You must supply your own legally obtained files.

### Game-Specific Configs

- **Diablo II Resurrected — Loot Filter**: Highlights high-value drops for Battle.net and single player
- **Fallout 76 — INI & Mods**: Performance and stability improvements
- **Arc Raiders — Match Optimizations**: Shorter transition videos and optimized config for VRR

## Utilities

### Monitor Control

| Script | Description |
|--------|-------------|
| Auto Detect Displays | Detect and apply recommended monitor config |
| Set Resolution | Change the resolution of a connected monitor |
| Set Brightness | Adjust monitor brightness |
| Change Orientation | Rotate a monitor |
| Scale Monitors | Change display scaling |
| Set Primary Monitor | Designate the primary display |
| Extend Displays | Extend across multiple monitors |
| Duplicate Displays | Mirror displays |
| Disable / Enable Monitor | Toggle a monitor on or off |
| Manage Arrangement | Set the physical arrangement of monitors |
| Reset Scaling | Revert scaling to default |

### Printers

| Script | Description |
|--------|-------------|
| CUPS | Install the CUPS printing system |
| Epson Drivers | Install Epson printer drivers |
| HP Drivers | Install HP printer drivers |

### System Utilities

| Script | Description |
|--------|-------------|
| Bluetooth Manager | Manage Bluetooth devices |
| WiFi Manager | Manage wireless connections |
| Service Manager | Enable, disable, and manage systemd services |
| Numlock on Startup | Enable Num Lock at boot |
| Auto Mount Drive | Automate mounting a drive at startup |
| Ollama | Manage Ollama (local AI model runner) |
| US Locale Setup | Fix US UTF-8 locale and folder listings |

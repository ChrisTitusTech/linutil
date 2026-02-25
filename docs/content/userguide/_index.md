---
title: User Guide
weight: 2
---

Welcome to the official User Guide for **Linutil**, Chris Titus Tech's Linux Utility!

## What is Linutil?

Linutil is a distro-agnostic toolbox designed to simplify everyday Linux tasks. Built in Rust for performance and reliability, it provides an interactive terminal UI (TUI) that helps you:

- **Install Applications**: Quickly set up popular software for your Linux system
- **System Setup**: Configure your distro with optimized settings and tools
- **Security**: Apply firewall baselines and harden your system
- **Utilities**: Manage monitors, printers, Bluetooth, WiFi, and more
- **Gaming**: Set up gaming dependencies and emulators

## Who Should Use Linutil?

Linutil is designed for:

- **Linux Beginners**: Wanting an easy way to set up a fresh install
- **Power Users**: Needing quick access to common configuration tasks
- **Developers**: Setting up clean development environments fast
- **Gamers**: Installing gaming dependencies and optimizing Linux for gaming
- **Privacy-Conscious Users**: Applying firewall rules and security hardening

## Getting Started

New to Linutil? Start here:

1. **[Getting Started Guide](getting-started/)** - How to run Linutil and navigate the TUI
2. **[Application Setup](store/)** - Installing software via the TUI
3. **[System Setup](tweaks/)** - Distro-specific setup and configuration
4. **[Features & Utilities](features/)** - Security, gaming, and utility tools
5. **[Automation](automation/)** - Run Linutil unattended with a config file

## Running Linutil

### Stable Branch (Recommended)

```bash
curl -fsSL https://christitus.com/linux | sh
```

### Dev Branch

```bash
curl -fsSL https://christitus.com/linuxdev | sh
```

## Main Categories

### Applications Setup

Browse and install hundreds of popular Linux applications from within the TUI. Categories include browsers, developer tools, communication apps, design tools, and more.

**[Read the Application Setup Guide →](store/)**

### System Setup

Distro-specific scripts for Arch, Fedora, Debian, Ubuntu, and more. Includes AUR helpers, desktop environment installers, driver setup, and system configuration.

**[Read the System Setup Guide →](tweaks/)**

### Security

Apply firewall baselines using UFW or FirewallD, following CTT's recommended security rules.

**[Read the Features Guide →](features/)**

### Utilities

Tools for monitor management, printer setup, Bluetooth, WiFi, service management, and more.

**[Read the Features Guide →](features/)**

### Gaming

Install gaming dependencies, emulators, and game-specific optimizations.

**[Read the Features Guide →](features/)**

### Automation

Run Linutil automatically with a TOML config file for scripted or batch setups.

**[Read the Automation Guide →](automation/)**

## Quick Links

| I want to... | Go to... |
|--------------|----------|
| Run Linutil for the first time | [Getting Started](getting-started/) |
| Install applications | [Application Setup](store/) |
| Set up Arch Linux | [System Setup](tweaks/) |
| Harden my firewall | [Features & Utilities](features/) |
| Automate Linutil for multiple machines | [Automation](automation/) |

## Safety and Best Practices

Before using Linutil:

- Read what each script does before running it
- Test on non-production systems when trying new configurations
- Keep backups of important configuration files

## Getting Help

Need assistance?

- **Documentation**: You're reading it! Use the navigation menu
- **FAQ**: Check [Frequently Asked Questions](../faq/)
- **Known Issues**: Review [Known Issues](../knownissues/)
- **Discord**: Join the [community Discord](https://discord.gg/RUbZUZyByQ)
- **GitHub**: Report bugs on [GitHub Issues](https://github.com/ChrisTitusTech/linutil/issues)

## Contributing

Want to help improve Linutil?

- **Report Bugs**: Submit issues on GitHub
- **Suggest Features**: Open feature requests
- **Contribute Scripts**: Add new bash scripts
- **Improve Docs**: Help expand this documentation

**[Read Contributing Guide →](../contributing/)**

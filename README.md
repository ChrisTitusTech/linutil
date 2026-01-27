# Chris Titus Tech's Linux Utility

[![Version](https://img.shields.io/github/v/release/ChrisTitusTech/linutil?color=%230567ff&label=Latest%20Release&style=for-the-badge)](https://github.com/ChrisTitusTech/linutil/releases/latest)
![GitHub Downloads (specific asset, all releases)](https://img.shields.io/github/downloads/ChrisTitusTech/linutil/linutil?label=Total%20Downloads&style=for-the-badge)
[![Crates.io Version](https://img.shields.io/crates/v/linutil_tui?style=for-the-badge&color=%23af3a03)](https://crates.io/crates/linutil_tui)
[![](https://dcbadge.limes.pink/api/server/https://discord.gg/RUbZUZyByQ?theme=default-inverted&style=for-the-badge)](https://discord.gg/RUbZUZyByQ)
![Preview](/.github/preview.gif)

**Linutil** is a distro-agnostic toolbox designed to simplify everyday Linux tasks. It helps you set up applications and optimize your system for specific use cases. The utility is actively developed in Rust 🦀, providing performance and reliability.

> [!NOTE]
> Since the project is still in active development, you may encounter some issues. Please consider [submitting feedback](https://github.com/ChrisTitusTech/linutil/issues) if you do.

## 💡 Usage
To get started, pick which branch you would like to use, then run the command in your terminal:
### Stable Branch (Recommended)
```bash
curl -fsSL https://christitus.com/linux | sh
```
### Dev branch
```bash
curl -fsSL https://christitus.com/linuxdev | sh
```

### CLI arguments

View available options by running:

```bash
linutil --help
```

For installer options:

```bash
curl -fsSL https://christitus.com/linux | sh -s -- --help
```

## ⬇️ Installation

Linutil is also available as a package in various repositories:

[![Packaging status](https://repology.org/badge/vertical-allrepos/linutil.svg)](https://repology.org/project/linutil/versions)

<details>
  <summary>Arch Linux</summary>

Linutil can be installed on [Arch Linux](https://archlinux.org) with three different [AUR](https://aur.archlinux.org) packages:

- `linutil` - Stable release compiled from source
- `linutil-bin` - Stable release pre-compiled
- `linutil-git` - Compiled from the last commit (not recommended)

by running:

```bash
git clone https://aur.archlinux.org/<package>.git
cd <package>
makepkg -si
```

Replace `<package>` with your preferred package.

If you use [yay](https://github.com/Jguer/yay), [paru](https://github.com/Morganamilo/paru) or any other [AUR Helper](https://wiki.archlinux.org/title/AUR_helpers), it's even simpler:

```bash
paru -S linutil
```

Replace `paru` with your preferred helper and `linutil` with your preferred package.

</details>
<details>
  <summary>OpenSUSE</summary>
  
Linutil can be installed on OpenSUSE with:
```bash
sudo zypper install linutil
```

</details>
<details>
  <summary>Cargo</summary>

Linutil can be installed via [Cargo](https://doc.rust-lang.org/cargo) with:

```bash
cargo install linutil_tui
```

Note that crates installed using `cargo install` require manual updating with `cargo install --force` (update functionality is [included in LinUtil](https://christitustech.github.io/linutil/userguide/#applications-setup))

</details>

## Configuration

Linutil supports configuration through a TOML config file. Path to the file can be specified with `--config` (or `-c`).

Available options:
- `auto_execute` - A list of commands to execute automatically (can be combined with `--skip-confirmation`)
- `skip_confirmation` - Boolean ( Equal to `--skip-confirmation`)
- `size_bypass` - Boolean ( Equal to `--size-bypass` )

Example config:
```toml
# example_config.toml

auto_execute = [
    "Fastfetch",
    "Alacritty",
    "Kitty"
]

skip_confirmation = true
size_bypass = true
```

```bash
linutil --config /path/to/example_config.toml
```

## 💖 Support

If you find Linutil helpful, please consider giving it a ⭐️ to show your support!

## 🎓 Documentation

For comprehensive information on how to use Linutil, visit the [Linutil Official Documentation](https://chris-titus-docs.github.io/linutil-docs/).

## 🛠 Contributing

We welcome contributions from the community! Before you start, please review our [Contributing Guidelines](.github/CONTRIBUTING.md) to understand how to make the most effective and efficient contributions.

[Official LinUtil Roadmap](https://chris-titus-docs.github.io/linutil-docs/roadmap/)

Docs are now [here](https://github.com/Chris-Titus-Docs/linutil-docs)

## 🏅 Thanks to All Contributors

Thank you to everyone who has contributed to the development of Linutil. Your efforts are greatly appreciated, and you're helping make this tool better for everyone!

[![Contributors](https://contrib.rocks/image?repo=ChrisTitusTech/linutil)](https://github.com/ChrisTitusTech/linutil/graphs/contributors)

## 📜 Contributor Milestones

- 2024/07 - Original Linutil Rust TUI was developed by [@JustLinuxUser](https://github.com/JustLinuxUser).
- 2024/09 - TabList (Left Column) and various Rust Core/TUI Improvements developed by [@lj3954](https://github.com/lj3954)
- 2024/09 - Cargo Publish, AUR, Rust, and Bash additions done by [@koibtw](https://github.com/koibtw)
- 2024/09 - Rust TUI Min/Max, MultiSelection, and Bash additions done by [@jeevithakannan2](https://github.com/jeevithakannan2)
- 2024/09 - Various bash updates and standardization done by [@nnyyxxxx](https://github.com/nnyyxxxx)
- 2024/09 - Multiple bash script additions done by [@guruswarupa](https://github.com/guruswarupa)

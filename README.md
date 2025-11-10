# Linutil (Fork) – TuxLux40 Edition

<!-- Upstream project badges retained for context -->

[![Upstream Version](https://img.shields.io/github/v/release/ChrisTitusTech/linutil?color=%230567ff&label=Upstream%20Release&style=for-the-badge)](https://github.com/ChrisTitusTech/linutil/releases/latest)
[![Fork Activity](https://img.shields.io/github/commit-activity/m/TuxLux40/linutil?style=for-the-badge&color=%23b95eff)](https://github.com/TuxLux40/linutil)
[![Crates.io Version](https://img.shields.io/crates/v/linutil_tui?style=for-the-badge&color=%23af3a03)](https://crates.io/crates/linutil_tui)
[![Discord (Upstream)](https://dcbadge.limes.pink/api/server/https://discord.gg/RUbZUZyByQ?theme=default-inverted&style=for-the-badge)](https://discord.gg/RUbZUZyByQ)
![Preview](/.github/preview.gif)

**Linutil (Fork)** is a personalized evolution of Chris Titus Tech's Linux Toolbox, maintained by **@TuxLux40**. It builds upon the upstream project's Rust 🦀 foundation while experimenting with new post-install flows, script organization, and dotfile integration.

> This repository is **not the upstream source**. For the original project visit: https://github.com/ChrisTitusTech/linutil

> [!NOTE]
> This fork evolves independently; issues specific to fork changes (postinstall orchestration, reorganized tabs, new scripts) should be reported here: https://github.com/TuxLux40/linutil/issues
> Upstream issues unrelated to fork changes belong at: https://github.com/ChrisTitusTech/linutil/issues

## 🔀 Fork Highlights

- Postinstall orchestrator with multi-select optional provisioning (Basic + Build tools baseline, then interactive).
- Enhanced script categorization (security/system/application) and new VPN, locale, and hardware setup helpers.
- Dotfiles bundle: fish, starship, ghostty, fastfetch, shell setup automation.
- Exposed Postinstall tab in the TUI for one-click setup.
- Logging of post-install actions to `~/.local/share/linutil/`.

## ✅ Upstream Compatibility

Most upstream usage patterns still apply. The install script URLs below point to the original distribution endpoints (unchanged). When using features unique to the fork, prefer cloning this repository directly.

## 💡 Usage

To get started, pick which branch you would like to use, then run the command in your terminal:

### Stable Branch (Upstream) (Recommended)

```bash
curl -fsSL https://christitus.com/linux | sh
```

### Dev Branch (Upstream)

```bash
curl -fsSL https://christitus.com/linuxdev | sh
```

### CLI arguments

View available options by running:

```bash
linutil --help
```

For installer options (Upstream):

```bash
curl -fsSL https://christitus.com/linux | sh -s -- --help
```

## ⬇️ Installation (Upstream Packages)

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

Linutil supports configuration through a TOML config file. Path to the file can be specified with `--config` (or `-c`). The fork introduces a Postinstall tab you can optionally run after launching the TUI.

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

If you find this fork helpful, give it a ⭐️ here: https://github.com/TuxLux40/linutil

Support upstream as well if you benefit from the original project.

## 🎓 Documentation

Upstream docs: https://chris-titus-docs.github.io/linutil-docs/

Fork-specific additions (Postinstall flow, new scripts) are currently documented in commit messages and README highlights. A dedicated fork doc section may be added later.

## 🛠 Contributing

Contributions to the fork are welcome. Feel free to open issues/PRs for:

- Improving postinstall script selection UX
- Adding reusable logging or dry-run features
- Extending dotfiles tooling or shell setup

Upstream contribution guidelines: `.github/CONTRIBUTING.md` (may reference original). Roadmap is managed upstream.

## 🏅 Attribution & Thanks

This fork stands on the shoulders of upstream contributors. Please visit the upstream repo to view full contributor history.

Upstream contributors badge:
[![Contributors](https://contrib.rocks/image?repo=ChrisTitusTech/linutil)](https://github.com/ChrisTitusTech/linutil/graphs/contributors)

## 📜 Contributor Milestones (Upstream Snapshot)

See upstream repository for authoritative historical milestones. Notable early contributions include:

- 2024/07 – Original Rust TUI by [@JustLinuxUser](https://github.com/JustLinuxUser)
- 2024/09 – Core/TUI improvements by [@lj3954](https://github.com/lj3954)
- 2024/09 – Packaging and script expansions by [@adamperkowski](https://github.com/adamperkowski)
- 2024/09 – TUI Min/Max & multi-select features by [@jeevithakannan2](https://github.com/jeevithakannan2)
- 2024/09 – Bash standardization by [@nnyyxxxx](https://github.com/nnyyxxxx)
- 2024/09 – Additional bash scripts by [@guruswarupa](https://github.com/guruswarupa)

Fork additions (2025): Postinstall orchestration, reorganization of tabs, dotfile integration by @TuxLux40.

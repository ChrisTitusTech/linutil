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
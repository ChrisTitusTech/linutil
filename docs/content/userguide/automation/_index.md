---
title: Automation
weight: 6
---

Linutil supports automation via a TOML config file. This lets you run predefined scripts automatically — useful for setting up multiple machines, provisioning servers, or scripting a consistent Linux environment.

## Config File

Create a TOML file with your desired settings:

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

Then run Linutil with your config:

```bash
linutil --config /path/to/example_config.toml
```

Or via the one-liner:

```bash
curl -fsSL https://christitus.com/linux | sh -s -- --config /path/to/example_config.toml
```

## Config Options

| Option | Type | Description |
|--------|------|-------------|
| `auto_execute` | list of strings | Script names to run automatically on launch |
| `skip_confirmation` | boolean | Skip confirmation prompts before running scripts |
| `size_bypass` | boolean | Bypass terminal size requirements |

## CLI Flags

The same options are available as command-line flags:

```bash
linutil --skip-confirmation --size-bypass
```

| Flag | Description |
|------|-------------|
| `--config` / `-c` | Path to TOML config file |
| `--skip-confirmation` | Skip all confirmation prompts |
| `--size-bypass` | Bypass minimum terminal size check |

## Use Cases

### Provision a New Machine

Create a config that installs your standard set of tools:

```toml
auto_execute = [
    "Bash Prompt",
    "Fastfetch",
    "VS Code",
    "Docker",
    "ZSH Prompt"
]

skip_confirmation = true
```

Run it on any new Linux install to get your environment set up in one shot.

### Server Setup

```toml
auto_execute = [
    "Full System Update",
    "UFW Firewall Baselines (CTT)",
    "Docker"
]

skip_confirmation = true
```

### Finding Script Names

Script names in `auto_execute` must match exactly as they appear in the Linutil TUI. Browse the TUI to find the exact name, or check the auto-generated [Walkthrough](../walkthrough/) page for a complete list.

> [!TIP]
> Use `--skip-confirmation` together with `auto_execute` for fully unattended runs. Without it, Linutil will still pause and ask before executing each script.

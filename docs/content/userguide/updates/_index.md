---
title: Updating Linutil
weight: 5
---

Linutil is actively developed and updated frequently. There are a few ways to keep your installation current.

## Running the Latest Version Directly

The simplest way to always use the latest release is to run the curl command each time:

```bash
curl -fsSL https://christitus.com/linux | sh
```

This always pulls the latest stable release without any local install needed.

## Updating a Local Install

If you installed Linutil locally (via Cargo, AUR, or openSUSE packages), use the appropriate method to update.

### Linutil Updater (Built-in)

The easiest way to update a Cargo-based install is the **Linutil Updater** script inside the tool itself:

1. Run Linutil
2. Navigate to **Applications Setup**
3. Select **Linutil Updater**
4. The script will update your local `linutil_tui` crate

### Cargo

```bash
cargo install --force linutil_tui
```

### Arch Linux (AUR)

```bash
# Using paru
paru -Syu linutil

# Using yay
yay -Syu linutil
```

### openSUSE

```bash
sudo zypper update linutil
```

## Dev Branch

To test the latest unreleased features, use the dev branch:

```bash
curl -fsSL https://christitus.com/linuxdev | sh
```

> [!WARNING]
> The dev branch may contain untested or unstable features. Not recommended for daily use.

## Checking the Current Version

After installing Linutil locally, you can check the version with:

```bash
linutil --version
```

## Release Notes

All releases and changelogs are available on the [GitHub Releases page](https://github.com/ChrisTitusTech/linutil/releases).

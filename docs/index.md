# Welcome to the LinUtil Documentation!

[![Version](https://img.shields.io/github/v/release/ChrisTitusTech/linutil?color=%230567ff&label=Latest%20Release&style=for-the-badge)](https://github.com/ChrisTitusTech/linutil/releases/latest)
![GitHub Downloads (specific asset, all releases)](https://img.shields.io/github/downloads/ChrisTitusTech/linutil/linutil?label=Total%20Downloads&style=for-the-badge)
[![](https://dcbadge.limes.pink/api/server/https://discord.gg/bujFYKAHSp)](https://discord.gg/bujFYKAHSp)

[![Crates.io Version](https://img.shields.io/crates/v/linutil_tui?style=for-the-badge&color=%23af3a03)](https://crates.io/crates/linutil_tui) [![linutil AUR Version](https://img.shields.io/aur/version/linutil?style=for-the-badge&label=%5BAUR%5D%20linutil&color=%23230567ff)](https://aur.archlinux.org/packages/linutil) [![linutil-bin AUR Version](https://img.shields.io/aur/version/linutil-bin?style=for-the-badge&label=%5BAUR%5D%20linutil-bin&color=%23230567ff)](https://aur.archlinux.org/packages/linutil-bin)

## Running the latest release of LinUtil

To get started, run the following command in your terminal:

### Stable branch

```
curl -fsSL https://christitus.com/linux | sh
```
---

### Installation

LinUtil is also available as a package in various repositories:

[![Packaging status](https://repology.org/badge/vertical-allrepos/linutil.svg)](https://repology.org/project/linutil/versions)

<details>
  <summary>Arch Linux</summary>

LinUtil can be installed on [Arch Linux](https://archlinux.org) with three different [AUR](https://aur.archlinux.org) packages:

- `linutil` - Stable release compiled from source
- `linutil-bin` - Stable release pre-compiled
- `linutil-git` - Compiled from the last commit (not recommended)

by running:

```bash
git clone https://aur.archlinux.org/<package>.git
cd linutil
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
  <summary>Cargo</summary>

LinUtil can be installed via [Cargo](https://doc.rust-lang.org/cargo) with:

```bash
cargo install linutil
```

Note that crates installed using `cargo install` require manual updating with `cargo install --force` (update functionality is [included in LinUtil](https://christitustech.github.io/linutil/userguide/#applications-setup))

</details>

---

After you've ran the command, you should see a GUI on your screen; It will look something like this:

![preview](assets/preview.gif)

!!! info

    LinUtil is updated weekly as of the time of writing. Consequently, features and functionalities may evolve, and the documentation may not always reflect the most current images or information.

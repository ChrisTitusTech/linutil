## Chris Titus Tech's Linux Utility

![pv](https://i.imgur.com/quoAwXf.png)

## Usage

Open your terminal and paste this command
```bash
curl -fsSL https://github.com/ChrisTitusTech/linutil/releases/latest/download/start.sh | sh
```

## Current Features

- Full System Update
- Removal of Obsolete Packages
- Setup system for specific tasks (Gaming, Compiling)
- Setup specific software on the system (Alacritty, Kitty, Rofi)

## Supported Systems

Linutil itself should run perfectly on most Linux systems with Rust installed. However, some specific features may rely on distribution-specific components (e.g. package manager).

- Debian (100% supported)
- Fedora 22+ (100% supported)
- Arch Linux (100% supported)
- OpenSUSE (100% supported)
- Red Hat Enterprise Linux (RHEL) and Fedora versions prior to 22 (43% supported)
- Gentoo (29% supported)
- Void Linux (29% supported)
- NixOS and other systems with Nix (29% supported)
- Slackware (29% supported)
- Alpine Linux (29% supported)

Derivatives of these distributions are included as long as they use the same package manager. Debian works with both APT and Nala, however around 86% of features use APT.

## Contributing

### Adding an entry to the main menu

Entries that you see in the main menu are defined in the src/list.rs file and are structured like this:

``` rust
ListNode {
    name: "[ENTRY NAME]",
    command: "[COMMAND]"
},
```

where [ENTRY NAME] is displayed on the main menu (e.g. Full System Update)

and [COMMAND] is ran when that entry is ran (e.g. apt-get full-upgrade -y)

### Adding a script to run for your entry

Script are located in the src/commands/ directory. If you want a script to be ran when you're entry is selected, you must set the entry command as follows:

``` bash
include_str!("commands/[YOUR_SCRIPT].sh"),
```

where [YOUR_SCRIPT] is the name of your script.

If you want to run a script from the web instead, the command should be more like this:

``` bash
curl -s https://[LINK_TO_YOUR_SCRIPT].sh | sh
```

where [LINK_TO_YOUR_SCRIPT] takes you to your script in raw format. Run the command without the "| sh" at the end to make sure it's correct.

## Credits

Removal of Obsolete Packages, README, support for doas and su in place of sudo and lots of support for multiple distros by [@AlbydST](https://github.com/AlbydST)

Rust Shell written by [@JustLinuxUser](https://github.com/JustLinuxUser)

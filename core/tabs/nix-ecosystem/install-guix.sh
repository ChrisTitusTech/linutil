#!/bin/sh -e

. ../common-script.sh

checkArch
checkEscalationTool
checkCommandRequirements "curl"

if command_exists guix; then
    printf "%b\n" "${GREEN}GNU Guix is already installed.${RC}"
    guix --version
    exit 0
fi

printf "%b\n" "${YELLOW}Installing GNU Guix...${RC}"
printf "%b\n" "${CYAN}This will run the official Guix installation script.${RC}"
printf "%b\n" ""

# Download and run the official installer
cd /tmp
curl -fsSL https://git.savannah.gnu.org/cgit/guix.git/plain/etc/guix-install.sh -o guix-install.sh
chmod +x guix-install.sh

printf "%b\n" "${YELLOW}Running Guix installer (requires root)...${RC}"
"$ESCALATION_TOOL" sh guix-install.sh

# Clean up
rm -f guix-install.sh

printf "%b\n" ""
printf "%b\n" "${GREEN}╔════════════════════════════════════════════════════════════════════════════════╗${RC}"
printf "%b\n" "${GREEN}║                                                                                ║${RC}"
printf "%b\n" "${GREEN}║     ██████╗ ███╗   ██╗██╗   ██╗     ██████╗ ██╗   ██╗██╗██╗  ██╗               ║${RC}"
printf "%b\n" "${GREEN}║    ██╔════╝ ████╗  ██║██║   ██║    ██╔════╝ ██║   ██║██║╚██╗██╔╝               ║${RC}"
printf "%b\n" "${GREEN}║    ██║  ███╗██╔██╗ ██║██║   ██║    ██║  ███╗██║   ██║██║ ╚███╔╝                ║${RC}"
printf "%b\n" "${GREEN}║    ██║   ██║██║╚██╗██║██║   ██║    ██║   ██║██║   ██║██║ ██╔██╗                ║${RC}"
printf "%b\n" "${GREEN}║    ╚██████╔╝██║ ╚████║╚██████╔╝    ╚██████╔╝╚██████╔╝██║██╔╝ ██╗               ║${RC}"
printf "%b\n" "${GREEN}║     ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝      ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═╝               ║${RC}"
printf "%b\n" "${GREEN}║                                                                                ║${RC}"
printf "%b\n" "${GREEN}║                    ✓ GNU Guix installed successfully!                          ║${RC}"
printf "%b\n" "${GREEN}║                                                                                ║${RC}"
printf "%b\n" "${GREEN}╠════════════════════════════════════════════════════════════════════════════════╣${RC}"
printf "%b\n" "${CYAN}║                                                                                ║${RC}"
printf "%b\n" "${CYAN}║   GET STARTED                                                                  ║${RC}"
printf "%b\n" "${CYAN}║     guix search <package>         Search for packages                          ║${RC}"
printf "%b\n" "${CYAN}║     guix install <package>        Install a package                            ║${RC}"
printf "%b\n" "${CYAN}║     guix upgrade                  Upgrade all packages                         ║${RC}"
printf "%b\n" "${CYAN}║     guix pull                     Update Guix itself                           ║${RC}"
printf "%b\n" "${CYAN}║                                                                                ║${RC}"
printf "%b\n" "${GREEN}╠════════════════════════════════════════════════════════════════════════════════╣${RC}"
printf "%b\n" "${YELLOW}║                                                                                ║${RC}"
printf "%b\n" "${YELLOW}║   RESOURCES                                                                    ║${RC}"
printf "%b\n" "${YELLOW}║     Homepage:     https://guix.gnu.org                                         ║${RC}"
printf "%b\n" "${YELLOW}║     Manual:       https://guix.gnu.org/manual                                  ║${RC}"
printf "%b\n" "${YELLOW}║     Packages:     https://packages.guix.gnu.org                                ║${RC}"
printf "%b\n" "${YELLOW}║     Cookbook:     https://guix.gnu.org/cookbook                                ║${RC}"
printf "%b\n" "${YELLOW}║                                                                                ║${RC}"
printf "%b\n" "${GREEN}╚════════════════════════════════════════════════════════════════════════════════╝${RC}"
printf "%b\n" ""
printf "%b\n" "${CYAN}Log out and back in, or run: source /etc/profile${RC}"

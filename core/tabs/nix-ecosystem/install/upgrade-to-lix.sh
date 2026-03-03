#!/bin/sh -e

. ../../common-script.sh

upgradeToLix() {
    printf "%b\n" "${YELLOW}Upgrading Nix to Lix...${RC}"

    if ! command_exists nix; then
        printf "%b\n" "${RED}Nix is not installed.${RC}"
        printf "%b\n" "${YELLOW}Use 'Install Lix' option for fresh installs.${RC}"
        return 1
    fi

    printf "%b\n" "${CYAN}Current version:${RC}"
    nix --version

    printf "%b\n" "${YELLOW}Running Lix upgrade...${RC}"
    "$ESCALATION_TOOL" --preserve-env=PATH nix run \
        --experimental-features "nix-command flakes" \
        --extra-substituters https://cache.lix.systems \
        --extra-trusted-public-keys "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=" \
        'git+https://git.lix.systems/lix-project/lix' -- \
        upgrade-nix \
        --extra-substituters https://cache.lix.systems \
        --extra-trusted-public-keys "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="

    printf "%b\n" "${GREEN}Upgrade complete.${RC}"
    printf "%b\n" "${CYAN}New version:${RC}"
    nix --version
}

checkArch
checkEscalationTool
upgradeToLix

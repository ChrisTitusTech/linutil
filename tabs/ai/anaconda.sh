#!/bin/sh -e

. ../common-script.sh

installAnaconda() {
    clear
    printf "%b\n" "${YELLOW}Checking if Anaconda is already installed...${RC}"

    # Check if Anaconda is already installed
    if command_exists conda; then
        printf "%b\n" "${GREEN}Anaconda is already installed.${RC}"
    else
        printf "%b\n" "${YELLOW}Installing Anaconda...${RC}"
        wget https://repo.anaconda.com/archive/Anaconda3-2023.03-1-Linux-x86_64.sh -O /tmp/anaconda.sh
        $ESCALATION_TOOL bash /tmp/anaconda.sh -b -p $HOME/anaconda3
        $ESCALATION_TOOL rm /tmp/anaconda.sh
        $ESCALATION_TOOL echo "export PATH=\"\$HOME/anaconda3/bin:\$PATH\"" >> $HOME/.bashrc
        source $HOME/.bashrc
        printf "%b\n" "${GREEN}Anaconda installed successfully.${RC}"
    fi
}

listEnvironments() {
    clear
    printf "%b\n" "${YELLOW}Listing all Anaconda environments...${RC}"
    conda env list
}

createEnvironment() {
    clear
    printf "%b\n" "${YELLOW}Creating a new Anaconda environment${RC}"
    printf "%b\n" "${YELLOW}Enter the name for the new environment:${RC}"
    read -r env_name

    printf "%b\n" "${YELLOW}Creating the environment '$env_name'...${RC}"
    conda create -n "$env_name" python=3.9 -y
    printf "%b\n" "${GREEN}Environment '$env_name' created successfully.${RC}"
}

deleteEnvironment() {
    clear
    listEnvironments
    printf "%b\n" "${YELLOW}Enter the name of the environment you want to delete:${RC}"
    read -r env_name

    printf "%b\n" "${YELLOW}Deleting the environment '$env_name'...${RC}"
    conda env remove -n "$env_name" -y
    printf "%b\n" "${GREEN}Environment '$env_name' deleted successfully.${RC}"
}

activateEnvironment() {
    clear
    listEnvironments
    printf "%b\n" "${YELLOW}Enter the name of the environment you want to activate:${RC}"
    read -r env_name

    printf "%b\n" "${YELLOW}Activating the environment '$env_name'...${RC}"
    conda activate "$env_name"
    printf "%b\n" "${GREEN}Environment '$env_name' activated successfully.${RC}"
}

installPackage() {
    clear
    activateEnvironment
    printf "%b\n" "${YELLOW}Enter the name of the package you want to install:${RC}"
    read -r package_name

    printf "%b\n" "${YELLOW}Installing the package '$package_name'...${RC}"
    conda install -n "$env_name" "$package_name" -y
    printf "%b\n" "${GREEN}Package '$package_name' installed successfully.${RC}"
}

menu() {
    while true; do
        clear
        printf "%b\n" "${YELLOW}Anaconda Management${RC}"
        printf "%b\n" "${YELLOW}=================${RC}"
        echo "1. Install Anaconda"
        echo "2. List Environments"
        echo "3. Create Environment"
        echo "4. Delete Environment"
        echo "5. Activate Environment"
        echo "6. Install Package"
        echo "7. Exit"
        echo -n "Choose an option: "
        read choice

        case $choice in
            1) installAnaconda ;;
            2) listEnvironments ;;
            3) createEnvironment ;;
            4) deleteEnvironment ;;
            5) activateEnvironment ;;
            6) installPackage ;;
            7) exit 0 ;;
            *) printf "%b\n" "${RED}Invalid option. Please try again.${RC}" ;;
        esac

        echo "Press [Enter] to continue..."
        read -r dummy
    done
}

checkEnv
checkEscalationTool
menu
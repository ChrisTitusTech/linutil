#!/bin/sh -e

. ../common-script.sh

installollama() {
    clear
    printf "%b\n" "${YELLOW}Checking if ollama is already installed...${RC}"

    # Check if ollama is already installed
    if command_exists ollama; then
        printf "%b\n" "${GREEN}ollama is already installed.${RC}"
    else
        printf "%b\n" "${YELLOW}Installing ollama...${RC}"
        curl -fsSL https://ollama.com/install.sh | sh
        $ESCALATION_TOOL systemctl start ollama 
    fi
}

list_models() {
    clear
    printf "%b\n" "${YELLOW}Listing all models available on your system...${RC}"
    ollama list
}

show_model_info() {
    clear
    list_models
    printf "%b\n" "${YELLOW}Enter the name of the model you want to show information for (e.g., llama3.1):${RC}"
    read -r model_name

    printf "%b\n" "${YELLOW}Showing information for model '$model_name'...${RC}"
    ollama show "$model_name"
}

# Function to display available models
display_models() {
    clear
    printf "%b\n" "${RED}Available Models${RC}"
    printf "1. Llama 3.1 - 8B (4.7GB)\n"
    printf "2. Llama 3.1 - 70B (40GB)\n"
    printf "3. Llama 3.1 - 405B (231GB)\n"
    printf "4. Phi 3 Mini - 3.8B (2.3GB)\n"
    printf "5. Phi 3 Medium - 14B (7.9GB)\n"
    printf "6. Gemma 2 - 2B (1.6GB)\n"
    printf "7. Gemma 2 - 9B (5.5GB)\n"
    printf "8. Gemma 2 - 27B (16GB)\n"
    printf "9. Mistral - 7B (4.1GB)\n"
    printf "10. Moondream 2 - 1.4B (829MB)\n"
    printf "11. Neural Chat - 7B (4.1GB)\n"
    printf "12. Starling - 7B (4.1GB)\n"
    printf "13. Code Llama - 7B (3.8GB)\n"
    printf "14. Llama 2 Uncensored - 7B (3.8GB)\n"
    printf "15. LLaVA - 7B (4.5GB)\n"
    printf "16. Solar - 10.7B (6.1GB)\n"
}

# Function to select model based on user input
select_model() {
    local choice="$1"
    case $choice in
        1) echo "llama3.1";;
        2) echo "llama3.1:70b";;
        3) echo "llama3.1:405b";;
        4) echo "phi3";;
        5) echo "phi3:medium";;
        6) echo "gemma2:2b";;
        7) echo "gemma2";;
        8) echo "gemma2:27b";;
        9) echo "mistral";;
        10) echo "moondream";;
        11) echo "neural-chat";;
        12) echo "starling-lm";;
        13) echo "codellama";;
        14) echo "llama2-uncensored";;
        15) echo "llava";;
        16) echo "solar";;
        *) echo "$choice";;  # Treat any other input as a custom model name
    esac
}

run_model() {
    clear
    display_models

    printf "%b\n" "${GREEN}Installed Models${RC}"
    installed_models=$(ollama list)
    printf "%b\n" "${installed_models}"

    printf "%b\n" "${YELLOW}Custom Models${RC}"
    custom_models=$(ollama list | grep 'custom-model-prefix') 

    printf "%b\n" "${YELLOW}Please select a model to run:${RC}"
    printf "%b\n" "${YELLOW}Enter the number corresponding to the model or enter the name of a custom model:${RC}"

    read -r model_choice

    model=$(select_model "$model_choice")

    printf "%b\n" "${YELLOW}Running the model: $model...${RC}"
    ollama run "$model"

}

create_model() {
    clear
    printf "%b\n" "${YELLOW}Let's create a new model in Ollama!${RC}"
    display_models

    # Prompt for base model
    printf "%b\n" "${YELLOW}Enter the base model (e.g. '13' for codellama):${RC}"
    read -r base_model

    model=$(select_model "$base_model")

    printf "%b\n" "${YELLOW}Running the model: $model...${RC}"
    ollama pull "$model"

    # Prompt for custom model name
    printf "%b\n" "${YELLOW}Enter a name for the new customized model:${RC}"
    read -r custom_model_name

    # Prompt for temperature setting
    printf "%b\n" "${YELLOW}Enter the desired temperature (higher values are more creative, lower values are more coherent, e.g., 1):${RC}"
    read -r temperature

    if [ -z "$temperature" ]; then
        temperature=${temperature:-1}
    fi

    # Prompt for system message
    printf "%b\n" "${YELLOW}Enter the system message for the model customization (e.g., 'You are Mario from Super Mario Bros. Answer as Mario, the assistant, only.'):${RC}"
    read -r system_message

    # Create the Modelfile
    printf "%b\n" "${YELLOW}Creating the Modelfile...${RC}"
    cat << EOF > Modelfile
FROM $base_model

# set the temperature to $temperature
PARAMETER temperature $temperature

# set the system message
SYSTEM """
$system_message
"""
EOF

    # Create the model in Ollama
    printf "%b\n" "${YELLOW}Creating the model in Ollama...${RC}"
    ollama create "$custom_model_name" -f Modelfile
    printf "%b\n" "${GREEN}Model '$custom_model_name' created successfully.${RC}"
}

# Function to remove a model
remove_model() {
    clear
    printf "%b\n" "${GREEN}Installed Models${RC}"
    installed_models=$(ollama list)
    printf "%b\n" "${installed_models}"

    printf "%b\n" "${YELLOW}Please select a model to remove:${RC}"
    printf "%b\n" "${YELLOW}Enter the name of the model you want to remove:${RC}"

    read -r model_to_remove

    if echo "$installed_models" | grep -q "$model_to_remove"; then
        printf "%b\n" "${YELLOW}Removing the model: $model_to_remove...${RC}"
        ollama rm "$model_to_remove"
        printf "%b\n" "${GREEN}Model '$model_to_remove' has been removed.${RC}"
    else
        printf "%b\n" "${RED}Model '$model_to_remove' is not installed. Exiting.${RC}"
        exit 1
    fi
}

menu() {
    while true; do
        clear
        printf "%b\n" "${YELLOW}Please select an option:${RC}"
        printf "1) List all models\n"
        printf "2) Show model information\n"
        printf "3) Create a new model\n"
        printf "4) Run a model\n"
        printf "5) Remove a model\n"
        printf "6) Exit\n"

        printf "%b" "${YELLOW}Enter your choice (1-5): ${RC}"
        read -r choice

        case $choice in
            1) list_models ;;
            2) show_model_info ;;
            3) create_model ;;
            4) run_model ;;
            5) remove_model;;
            6) printf "%b\n" "${GREEN}Exiting...${RC}"; exit 0 ;;
            *) printf "%b\n" "${RED}Invalid choice. Please try again.${RC}" ;;
        esac

        printf "%b\n" "${YELLOW}Press Enter to continue...${RC}"
        read -r dummy
    done
}

checkEnv
checkEscalationTool
installollama
menu


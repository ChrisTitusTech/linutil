#!/bin/sh -e

. ../common-script.sh

installollama() {
    clear
    printf "%b\n" "${YELLOW}Checking if ollama is already installed...${RC}"

    if command_exists ollama; then
        printf "%b\n" "${GREEN}ollama is already installed.${RC}"
    else
        printf "%b\n" "${YELLOW}Installing ollama...${RC}"
        curl -fsSL https://ollama.com/install.sh | "$ESCALATION_TOOL" sh
        "$ESCALATION_TOOL" startService ollama 
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
    printf "%b" "Enter the name of the model you want to show information for (e.g., llama3.1): "
    read -r model_name

    printf "%b\n" "${YELLOW}Showing information for model '$model_name'...${RC}"
    ollama show "$model_name"
}

display_models() {
    clear
    printf "%b\n" "${RED}Available Models${RC}"
    printf "%b\n" "1. Llama 3.1 - 8B (4.7GB)"
    printf "%b\n" "2. Llama 3.1 - 70B (40GB)"
    printf "%b\n" "3. Llama 3.1 - 405B (231GB)"
    printf "%b\n" "4. Phi 3 Mini - 3.8B (2.3GB)"
    printf "%b\n" "5. Phi 3 Medium - 14B (7.9GB)"
    printf "%b\n" "6. Gemma 2 - 2B (1.6GB)"
    printf "%b\n" "7. Gemma 2 - 9B (5.5GB)"
    printf "%b\n" "8. Gemma 2 - 27B (16GB)"
    printf "%b\n" "9. Mistral - 7B (4.1GB)"
    printf "%b\n" "10. Moondream 2 - 1.4B (829MB)"
    printf "%b\n" "11. Neural Chat - 7B (4.1GB)"
    printf "%b\n" "12. Starling - 7B (4.1GB)"
    printf "%b\n" "13. Code Llama - 7B (3.8GB)"
    printf "%b\n" "14. Llama 2 Uncensored - 7B (3.8GB)"
    printf "%b\n" "15. LLaVA - 7B (4.5GB)"
    printf "%b\n" "16. Solar - 10.7B (6.1GB)"
}

# Function to select model based on user input
select_model() {
    choice="$1"
    case $choice in
        1) printf "%b\n" "llama3.1";;
        2) printf "%b\n" "llama3.1:70b";;
        3) printf "%b\n" "llama3.1:405b";;
        4) printf "%b\n" "phi3";;
        5) printf "%b\n" "phi3:medium";;
        6) printf "%b\n" "gemma2:2b";;
        7) printf "%b\n" "gemma2";;
        8) printf "%b\n" "gemma2:27b";;
        9) printf "%b\n" "mistral";;
        10) printf "%b\n" "moondream";;
        11) printf "%b\n" "neural-chat";;
        12) printf "%b\n" "starling-lm";;
        13) printf "%b\n" "codellama";;
        14) printf "%b\n" "llama2-uncensored";;
        15) printf "%b\n" "llava";;
        16) printf "%b\n" "solar";;
        *) printf "%b\n" "$choice";;
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
    printf "%b\n" "${custom_models}"

    printf "%b" "Select a model to run: "
    printf "%b" "Enter the number corresponding to the model or enter the name of a custom model: "

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
    printf "%b" "Enter the base model (e.g. '13' for codellama): "
    read -r base_model

    model=$(select_model "$base_model")

    printf "%b\n" "${YELLOW}Running the model: $model...${RC}"
    ollama pull "$model"

    # Prompt for custom model name
    printf "%b" "Enter a name for the new customized model: "
    read -r custom_model_name

    # Prompt for temperature setting
    printf "%b" "Enter the desired temperature (higher values are more creative, lower values are more coherent, e.g., 1): "
    read -r temperature

    if [ -z "$temperature" ]; then
        temperature=${temperature:-1}
    fi

    # Prompt for system message
    printf "%b" "Enter the system message for the model customization (e.g., 'You are Mario from Super Mario Bros. Answer as Mario, the assistant, only.'): "
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

    printf "%b" "Please select a model to remove: "
    printf "%b" "Enter the name of the model you want to remove: "

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
        printf "%b\n" "1) List all models"
        printf "%b\n" "2) Show model information"
        printf "%b\n" "3) Create a new model"
        printf "%b\n" "4) Run a model"
        printf "%b\n" "5) Remove a model"
        printf "%b\n" "6) Exit"

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
        read -r _
    done
}

checkEnv
checkEscalationTool
installollama
menu


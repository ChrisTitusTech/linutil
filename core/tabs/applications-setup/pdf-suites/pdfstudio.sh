#!/bin/sh -e

. ../../common-script.sh

installPdfstudio() {
    if ! command_exists pdfstudio2024; then
        printf "%b\n" "${YELLOW}Installing PDF Studio...${RC}"
        curl -O https://download.qoppa.com/pdfstudio/PDFStudio_linux64.sh
        "$ESCALATION_TOOL" chmod +x PDFStudio_linux64.sh
        if sh PDFStudio_linux64.sh; then
            printf "%b\n" "${GREEN}PDF Studio installed successfully!${RC}"
        else
            printf "%b\n" "${RED}PDF Studio installation failed!${RC}"
        fi
        rm PDFStudio_linux64.sh
    else
        printf "%b\n" "${GREEN}PDF Studio is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installPdfstudio

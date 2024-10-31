#!/bin/sh -e

. ../../common-script.sh

installPdfstudioviewer() {
    if ! command_exists pdfstudioviewer2024; then
        printf "%b\n" "${YELLOW}Installing PDF Studio Viewer...${RC}"
        curl -O https://download.qoppa.com/pdfstudioviewer/PDFStudioViewer_linux64.sh
        "$ESCALATION_TOOL" chmod +x PDFStudioViewer_linux64.sh
        if sh PDFStudioViewer_linux64.sh; then
            printf "%b\n" "${GREEN}PDF Studio Viewer installed successfully!${RC}"
        else
            printf "%b\n" "${RED}Installation failed!${RC}"
        fi
        rm PDFStudioViewer_linux64.sh
    else
        printf "%b\n" "${GREEN}PDF Studio Viewer is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installPdfstudioviewer

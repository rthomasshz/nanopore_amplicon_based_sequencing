#!/bin/bash

# This script concatenates '.fastq' files in subdirectories within an input 
# directory and saves the concatenated files in an output directory.
# It also logs subdirectories that do not contain '.fastq' files.

# Display help and exit
function show_help {
    echo "Usage: $0 [-h] [-i input_directory] [-o output_directory]"
    echo "Options:"
    echo "  -h, --help        Show this help menu."
    echo "  -i, --input-dir   Input directory with subdirectories containing '.fastq' files."
    echo "  -o, --output-dir  Output directory for concatenated files."
    exit 0
}

# Parse command line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        -i|--input-dir) INPUT_DIR="$2"; shift ;;
        -o|--output-dir) OUTPUT_DIR="$2"; shift ;;
        *) echo "Unknown option: $1"; show_help ;;
    esac
    shift
done

# Prompt for input directory if not provided or invalid
while [[ -z "$INPUT_DIR" || ! -d "$INPUT_DIR" ]]; do
    [[ -n "$INPUT_DIR" ]] && echo "Invalid directory: '$INPUT_DIR'."
    read -e -p "Enter a valid input directory: " INPUT_DIR
done

# Prompt for output directory if not provided
[[ -z "$OUTPUT_DIR" ]] && read -e -p "Enter the output directory: " OUTPUT_DIR

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR" && echo "Output directory '$OUTPUT_DIR' created."

# Log file for subdirectories without '.fastq' files
NOT_FOUND_FILE="${OUTPUT_DIR}/not_found_files.txt"
touch "$NOT_FOUND_FILE"

# Concatenate files
for FOLDER in "${INPUT_DIR}"barcode*; do
    FOLDER_NAME=$(basename "$FOLDER")
    if compgen -G "${FOLDER}"/*.fastq > /dev/null; then
        cat "${FOLDER}"/*.fastq > "${OUTPUT_DIR}/${FOLDER_NAME}.fastq"
        echo "Concatenated files into ${OUTPUT_DIR}/${FOLDER_NAME}.fastq"
    else
        echo "No .fastq files found in $FOLDER. Skipping." >> "$NOT_FOUND_FILE"
    fi
done
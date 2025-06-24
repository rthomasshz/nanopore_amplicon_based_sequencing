#!/bin/bash

# This script processes '.fastq' files from an input directory,
# runs Porechop on each file, and saves the results in an output directory.
# It also logs any empty files that are skipped and warnings from Porechop.

# Display help and exit
function show_help {
    echo "Usage: $0 [-h] [-i input_directory] [-o output_directory]"
    echo "Options:"
    echo "  -h, --help        Show this help menu."
    echo "  -i, --input-dir   Input directory with '.fastq' files."
    echo "  -o, --output-dir  Output directory for processed files."
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

# Log files for skipped empty files and warnings
SKIPPED_FILES_LOG="${OUTPUT_DIR}/skipped_files.txt"
WARN_FILE="${OUTPUT_DIR}/warning.txt"
touch "$SKIPPED_FILES_LOG" "$WARN_FILE"

# Process each '.fastq' file
for FILE in "$INPUT_DIR"/barcode*.fastq; do
    if [[ -s "$FILE" ]]; then
        FILE_NAME=$(basename "$FILE")
        porechop -t 6 \
        --adapter_threshold 90 \
        --discard_middle \
        --middle_threshold 90 \
        --extra_end_trim 5 \
        -i "$FILE" -o "$OUTPUT_DIR/$FILE_NAME" 2>> "$WARN_FILE"
    else
        echo "Skipping empty file $FILE" >> "$SKIPPED_FILES_LOG"
    fi
done

# Print completion message
echo "Process completed. Check ${SKIPPED_FILES_LOG} for skipped files and ${WARN_FILE} for warnings from Porechop."
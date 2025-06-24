#!/bin/bash

# This script processes '.fastq' files from an input directory,
# runs fastp on each file, and saves the results in an output directory.
# It also logs any empty files that are skipped and warnings from fastp.

# Function to display help and exit
function show_help {
    echo "Usage: $0 [-h] [-i input_directory] [-o output_directory] [-r length_required] [-l length_limit]"
    echo "Options:"
    echo "  -h, --help            Show this help menu."
    echo "  -i, --input-dir       Input directory with '.fastq' files."
    echo "  -o, --output-dir      Output directory for processed files."
    echo "  -r, --length-required Minimum required length for reads."
    echo "  -l, --length-limit    Maximum allowed length for reads."
    exit 0
}

# Parse command line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        -i|--input-dir) INPUT_DIR="$2"; shift ;;
        -o|--output-dir) OUTPUT_DIR="$2"; shift ;;
        -r|--length-required) LENGTH_REQUIRED="$2"; shift ;;
        -l|--length-limit) LENGTH_LIMIT="$2"; shift ;;
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

# Prompt for length_required if not provided
while [[ -z "$LENGTH_REQUIRED" ]]; do
    read -e -p "Enter the minimum required length for reads (e.g., 585): " LENGTH_REQUIRED
done

# Prompt for length_limit if not provided
while [[ -z "$LENGTH_LIMIT" ]]; do
    read -e -p "Enter the maximum allowed length for reads (e.g., 704): " LENGTH_LIMIT
done

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR" && echo "Output directory '$OUTPUT_DIR' created."

# Log files
SKIPPED_FILES_LOG="${OUTPUT_DIR}/skipped_files.txt"
WARN_FILE="${OUTPUT_DIR}/warnings.txt"

# Create log files if they don't exist
touch "$SKIPPED_FILES_LOG"
touch "$WARN_FILE"

# Process each '.fastq' file
for FILE in "${INPUT_DIR}"/*.fastq; do

    # Check if the file has content
    if [[ -s "$FILE" ]]; then

        # Extract the name of the file without extension
        FILE_NAME=$(basename "$FILE" .fastq)

        # Create a subdirectory for the current file
        SUBDIR="$OUTPUT_DIR/$FILE_NAME"
        mkdir -p "$SUBDIR"

        # Run fastp
        fastp -i "$FILE" \
        --length_required "$LENGTH_REQUIRED" \
        --length_limit "$LENGTH_LIMIT" \
        -A \
        -W 10 \
        -M 10 \
        -w 6 \
        -o "$SUBDIR/$FILE_NAME.fastq" \
        -j "$SUBDIR/${FILE_NAME}.json" \
        -h "$SUBDIR/${FILE_NAME}.html" 2>> "$WARN_FILE"

    else
        # Log empty files that are skipped
        echo "Skipping empty file $FILE" >> "$SKIPPED_FILES_LOG"
    fi

done

# Print completion message
echo "Process complete. Check ${SKIPPED_FILES_LOG} for skipped files and ${WARN_FILE} for warnings from fastp."
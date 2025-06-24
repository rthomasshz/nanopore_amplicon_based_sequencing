#!/bin/bash

# This script recursively processes '.fastq' files from an input directory,
# runs Kraken2 on each file found in subdirectories, and saves the results in an output directory.
# It also logs any errors encountered during the process.

# Display help and exit
function show_help {
    echo "Usage: $0 [-h] [-i input_directory] [-o output_directory] [-d database]"
    echo "Options:"
    echo "  -h, --help        Show this help menu."
    echo "  -i, --input-dir   Input directory containing subdirectories with '.fastq' files."
    echo "  -o, --output-dir  Output directory for Kraken2 results."
    echo "  -d, --database    Directory of the Kraken2 database."
    exit 0
}

# Parse command line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        -i|--input-dir) INPUT_DIR="$2"; shift ;;
        -o|--output-dir) OUTPUT_DIR="$2"; shift ;;
        -d|--database) DATABASE="$2"; shift ;;
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

# Prompt for database directory if not provided
[[ -z "$DATABASE" ]] && read -e -p "Enter the Kraken2 database directory: " DATABASE

# Verify input directory exists
if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist."
    exit 1
fi

# Find and list all '.fastq' files in the input directory and subdirectories
FASTQ_FILES=$(find "$INPUT_DIR" -type f -name "*.fastq")
if [[ -z "$FASTQ_FILES" ]]; then
    echo "Error: No '.fastq' files found in the input directory '$INPUT_DIR'."
    exit 1
fi

# Log file for errors
ERROR_LOG="${OUTPUT_DIR}/error_log.txt"
touch "$ERROR_LOG"

# Create output directories
REPORT_DIR="${OUTPUT_DIR}/01-report/"
OUTPUT_TXT_DIR="${OUTPUT_DIR}/02-output/"
CLASSIFIED_DIR="${OUTPUT_DIR}/03-classified/"
UNCLASSIFIED_DIR="${OUTPUT_DIR}/04-unclassified/"

mkdir -p "$REPORT_DIR" "$OUTPUT_TXT_DIR" "$CLASSIFIED_DIR" "$UNCLASSIFIED_DIR"

# Process each '.fastq' file
while IFS= read -r FILE; do
    FILE_NAME=$(basename "$FILE" .fastq)
    kraken2 --db "$DATABASE" "$FILE" --use-names --confidence 0.1 --minimum-hit-groups 4 \
    --report "${REPORT_DIR}/${FILE_NAME}_report.txt" \
    --output "${OUTPUT_TXT_DIR}/${FILE_NAME}_output.txt" \
    --classified-out "${CLASSIFIED_DIR}/${FILE_NAME}_classified.fastq" \
    --unclassified-out "${UNCLASSIFIED_DIR}/${FILE_NAME}_unclassified.fastq" \
    --threads 6 || echo "Error processing $FILE_NAME" >> "$ERROR_LOG"
done <<< "$FASTQ_FILES"

echo "Process complete. Check ${ERROR_LOG} for errors."
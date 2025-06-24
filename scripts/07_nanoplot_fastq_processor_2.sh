#!/bin/bash

# Display help and exit
function show_help {
    echo "Usage: $0 [-h] [-i input_directory] [-o output_directory]"
    echo "Options:"
    echo "  -h, --help        Show this help menu."
    echo "  -i, --input-dir   Input directory with subdirectories containing '.fastq' files."
    echo "  -o, --output-dir  Output directory for NanoPlot results."
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
SKIPPED_FILES_LOG="${OUTPUT_DIR}/skipped_files.txt"
touch "$SKIPPED_FILES_LOG"

# Process files
for FOLDER in "${INPUT_DIR}"/barcode*; do
    FOLDER_NAME=$(basename "$FOLDER")
    
    # Check for .fastq files in the folder
    if compgen -G "${FOLDER}/*.fastq" > /dev/null; then
        for FILE in "${FOLDER}"/*.fastq; do
            if [[ -s "$FILE" ]]; then
                FILE_NAME=$(basename "$FILE" .fastq)
                PLOT_OUTPUT_DIR="${OUTPUT_DIR}/${FOLDER_NAME}/"
                mkdir -p "$PLOT_OUTPUT_DIR"
                OUTPUT_PREFIX="${FOLDER_NAME}_${FILE_NAME}_output"  # Define output prefix based on folder and file
                NanoPlot -t 6 --N50 --color blue --drop_outliers --fastq "$FILE" \
                    -o "$PLOT_OUTPUT_DIR" --tsv_stats --prefix "$OUTPUT_PREFIX"
            else
                echo "Skipping empty file $FILE" >> "$SKIPPED_FILES_LOG"
            fi
        done
    else
        echo "No .fastq files found in $FOLDER. Skipping." >> "$SKIPPED_FILES_LOG"
    fi
done

echo "Process completed. Check ${SKIPPED_FILES_LOG} for skipped files."

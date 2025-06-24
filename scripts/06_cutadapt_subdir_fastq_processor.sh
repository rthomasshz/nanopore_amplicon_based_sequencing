#!/bin/bash

# This script processes '.fastq' files from an input directory containing subdirectories
# and generates output in a structured manner.

# Function to display help and exit
function show_help {
    echo "Usage: $0 [-h] [-i input_directory] [-o output_directory]"
    echo "Options:"
    echo "  -h, --help            Show this help menu."
    echo "  -i, --input-dir       Input directory with subdirectories containing '.fastq' files."
    echo "  -o, --output-dir      Output directory for processed files."
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

# Process each subdirectory in the input directory
for SUBDIR in "$INPUT_DIR"/*; do
    if [[ -d "$SUBDIR" ]]; then
        BARCODE=$(basename "$SUBDIR")
        OUTPUT_SUBDIR="$OUTPUT_DIR/$BARCODE"
        mkdir -p "$OUTPUT_SUBDIR"

        # Process each '.fastq' file in the subdirectory
        for FILE in "$SUBDIR"/*.fastq; do
            if [[ -s "$FILE" ]]; then
                FILE_NAME=$(basename "$FILE" .fastq)

                # Run Cutadapt for primer trimming
                cutadapt \
                    -g XACTAAGAACGGCCATGCACC \
                    -g XCAGCAGCCGCGGTAATTCC \
                    -g XCAGCAGCCGCGGTAATTCC \
                    -a ^CAGCAGCCGCGGTAATTCC...ACTAAGAACGGCCATGCACCX \
                    -a GGTGCATGGCCGTTCTTAGTX \
                    -a CAGCAGCCGCGGTAATTCCX \
                    -a GGAATTACCGCGGCTGCTGX \
                    -b ACTAAGAACGGCCATGCACC \
                    -b CAGCAGCCGCGGTAATTCC \
                    -b GGTGCATGGCCGTTCTTAGT \
                    -b GGAATTACCGCGGCTGCTG \
                    --rc \
                    --times 6 \
                    -e 0.25 \
                    -o "$OUTPUT_SUBDIR/${FILE_NAME}_trimmed.fastq" \
                    "$FILE" \
                    --untrimmed-output "$OUTPUT_SUBDIR/${FILE_NAME}_untrimmed.fastq" \
                    --report=full > "$OUTPUT_SUBDIR/cutadapt_report.txt"

                # Combine trimmed files
                cat "$OUTPUT_SUBDIR/${FILE_NAME}_trimmed.fastq" "$OUTPUT_SUBDIR/${FILE_NAME}_untrimmed.fastq" > "$OUTPUT_SUBDIR/${FILE_NAME}.fastq"

                # Cleanup intermediate files
                rm -f "$OUTPUT_SUBDIR/${FILE_NAME}_trimmed.fastq" \
                      "$OUTPUT_SUBDIR/${FILE_NAME}_untrimmed.fastq"
            else
                echo "Skipping empty file $FILE"
            fi
        done
    fi
done

# Print completion message
echo "Processing complete. Outputs are in $OUTPUT_DIR."
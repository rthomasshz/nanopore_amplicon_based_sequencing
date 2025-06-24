# Nanopore Amplicon-Based Sequencing Workflow

This repository contains a complete and modular bioinformatics pipeline for processing Oxford Nanopore amplicon sequencing data, particularly targeting the 18S rRNA gene of arthropod-transmitted hemoparasites. The pipeline includes scripts for quality filtering, adapter and primer removal, taxonomic classification, and validation of unclassified reads.

## Overview of the Workflow

![Workflow overview](./Fig_1.png)
*Figure 1. General bioinformatics workflow for processing nanopore amplicon reads.*

---

## 1. Basecalling and Demultiplexing

**Script:** `01_basecalling_and_demultiplexing.sh`
**Tools:** Guppy v4.2.2
**Description:** Performs basecalling with the Super Accuracy (SUP) model and demultiplexing using Guppy. Only reads with barcodes at both ends are retained.

```bash
bash 01_basecalling_and_demultiplexing.sh \
  -i 08-raw_fast5/ \
  -o 07-guppy_output/ \
  -m ~/ont-guppy/data/dna_r10.4.1_e8.2_400bps_sup@v5.0.0/ \
  -b SQK-NBD114-96
```

Expected structure:

```
07-guppy_output/
├── basecalled/
│   └── pass/*.fastq
├── demultiplexed/
│   └── barcode01/*.fastq
│   └── barcode02/*.fastq
```

---

## 2. Concatenation of FASTQ Files

**Script:** `02-concat_fastq.sh`
**Description:** Concatenates all `.fastq` files from each barcode directory into one `.fastq` file per barcode.

```bash
bash 02-concat_fastq.sh -i /ruta/a/fastq/demultiplexados -o /ruta/a/output
```

---

## 3. First Quality Evaluation

* **Tool**: NanoPlot v1.42.0
* **Script**: `03-nanoplot_fastq_processor.sh`

```bash
bash 03-nanoplot_fastq_processor.sh -i <concat_fastq> -o <qc_nanoplot1>
```

---

## 4. Adapter and Chimera Removal

* **Tool**: Porechop v0.2.4
* **Script**: `04-porechop_fastq_processor.sh`

```bash
bash 04-porechop_fastq_processor.sh -i <qc_input> -o <porechop_output>
```

---

## 5. Length Filtering

* **Tool**: fastp v0.23.4
* **Range**: 577–831 bp
* **Script**: `05-fastp_fastq_processor.sh`

```bash
bash 05-fastp_fastq_processor.sh -i <input> -o <output> -r 577 -l 831
```

---

## 6. Primer Removal

* **Tool**: Cutadapt v3.3
* **Script**: `06_cutadapt_subdir_fastq_processor.sh`
* **Options**: `--rc`, `--times 6`, `-e 0.25`

```bash
bash 06_cutadapt_subdir_fastq_processor.sh -i <filtered_input> -o <trimmed_output>
```

---

## 7. Second Quality Evaluation

* **Tool**: NanoPlot v1.42.0
* **Script**: `07_nanoplot_fastq_processor_2.sh`

```bash
bash 07_nanoplot_fastq_processor_2.sh -i <trimmed_fastq_dir> -o <qc_nanoplot2>
```

---

## 8. MultiQC Summary (Run Twice)

* **Tool**: MultiQC v1.24.1
* **Script**: `multiqc_report.sh`

```bash
bash multiqc_report.sh -i <nanoplot_dir> -o <multiqc_output>
```

---

## 9. Taxonomic Classification

* **Tool**: Kraken2 v2.0.9
* **Database**: SILVA Ref NR 138.2
* **Script**: `08-kraken2_fastq_classifier.sh`
* **Options**: `--confidence 0.1`, `--minimum-hit-groups 4`

```bash
bash 08-kraken2_fastq_classifier.sh -i <trimmed_fastq> -o <kraken_output> -d <kraken_db>
```

---

## 10. Validation of Unclassified Reads

* **Tool**: MEGABLAST (BLASTn)
* **Script**: `megablast.sh`
* **Database**: `core_nt.00`
* **Thresholds**: ≥95% identity, ≥98% coverage, bitscore ≥50, E ≤0, Δbitscore ≥32

```bash
bash megablast.sh -i <fasta_unclassified> -o <blast_output>
```

---

## Figures and Supplementary Information

* `Fig_1.png`: General pipeline overview
* `Fig_2.png`: Consensus sequence generation and variant analysis

*Sections corresponding to 2.4.3 and 2.4.4 will be integrated in the next phase of documentation.*

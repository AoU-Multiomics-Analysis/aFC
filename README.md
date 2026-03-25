# aFC Pipeline

This repository contains WDL workflows for computing allelic Fold Change (aFC) from QTL mapping results.
The underlying aFC tool is described at https://github.com/secastel/aFC.

---

## Repository Structure

```
workflows/
  preprocess_AFC_inputs.wdl   # Step 1 – prepare VCF and expression BED for aFC
  aFC.wdl                     # Step 2 – run aFC, split by chromosome, and merge results
envs/
  Dockerfile                  # Docker image definition for the execution environment
```

---

## Workflows

### 1. `preprocess_AFC_inputs.wdl` – Preprocessing Workflow

**Workflow name:** `preprocess_workflow_parallel`

Prepares the genotype VCF and expression BED files so they meet the requirements of the aFC tool.
The two preprocessing tasks run in parallel.

#### Tasks

| Task | Description |
|------|-------------|
| `preprocess_expression_bed` | Re-compresses the expression BED file with `bgzip` and creates a `tabix` index (`.tbi`). This is required because aFC expects a bgzip-compressed, tabix-indexed BED file. |
| `annotate_vcf_ids` | Annotates variant IDs in the VCF to the format `CHROM:POS_REF_ALT` using `bcftools annotate`. This ensures variant IDs match the `sid` field format used in the QTL file. |

#### Inputs

| Input | Type | Description |
|-------|------|-------------|
| `vcf_file` | File | Input genotype VCF (any compression accepted by bcftools) |
| `expression_bed` | File | Expression BED file (gzipped) |
| `prefix` | String | Output file prefix |
| `memory` | Int | Memory in GB (default: 16) |
| `disk_space` | Int | Extra disk space in GB (default: 50) |
| `num_threads` | Int | Number of CPU threads (default: 8) |
| `num_preempt` | Int | Number of preemptible retries (default: 0) |

#### Outputs

| Output | Description |
|--------|-------------|
| `processed_expression_bed` | bgzip-compressed expression BED (`<prefix>.processed_expression.bed.gz`) |
| `processed_expression_bed_tbi` | tabix index for the expression BED |
| `annotated_vcf` | VCF with annotated variant IDs (`<prefix>.annotated.vcf.gz`) |
| `annotated_vcf_tbi` | tabix index for the annotated VCF |

---

### 2. `aFC.wdl` – aFC Workflow

**Workflow name:** `aFC_workflow_split_by_chr`

Runs the aFC tool per chromosome in parallel (scatter), then merges all per-chromosome results into a single output file.

#### Tasks

| Task | Description |
|------|-------------|
| `split_vcf_by_chr` | Subsets the input VCF to a single chromosome using `bcftools view` and indexes the result with `tabix`. |
| `run_afc` | Runs `aFC.py` on the per-chromosome VCF with the expression BED, covariates, and QTL file. Output is gzip-compressed. |
| `merge_afc_reports` | Concatenates all per-chromosome aFC result files into a single gzip-compressed file, preserving the header from the first file. |

#### Inputs

| Input | Type | Description |
|-------|------|-------------|
| `vcf_file` | File | Annotated, indexed genotype VCF (output of preprocessing workflow) |
| `vcf_index` | File | tabix index (`.tbi`) for the VCF |
| `expression_bed` | File | bgzip-compressed, indexed expression BED (output of preprocessing workflow) |
| `expression_bed_index` | File | tabix index (`.tbi`) for the expression BED |
| `covariates_file` | File | Covariates file in the format expected by aFC |
| `afc_qtl_file` | File | QTL file (see [QTL File Requirements](#qtl-file-requirements) below) |
| `prefix` | String | Output file prefix |
| `chromosomes` | Array[String]? | Optional list of chromosomes to process (defaults to chr1–chr22, chrX, chrY) |
| `memory` | Int | Memory in GB (default: 16) |
| `disk_space` | Int | Extra disk space in GB (default: 50) |
| `num_threads` | Int | Number of CPU threads (default: 8) |
| `num_preempt` | Int | Number of preemptible retries (default: 0) |

#### Outputs

| Output | Description |
|--------|-------------|
| `per_chr_afc_reports` | Array of per-chromosome aFC result files (`<prefix>.<chr>.aFC.txt.gz`) |
| `final_afc_report` | Merged aFC results for all chromosomes (`<prefix>.aFC.txt.gz`) |

---

## Data Preparation

### VCF File

- Must be compressed (`.vcf.gz`) and indexed (`.vcf.gz.tbi`).
- Variant IDs must follow the format `CHROM:POS_REF_ALT` to match the `sid` field in the QTL file.
  - If your VCF does not already use this format, run the `preprocess_AFC_inputs.wdl` workflow to annotate IDs automatically.

### Expression BED File

- Must be bgzip-compressed and tabix-indexed.
- If your expression BED is gzip-compressed but not bgzip-indexed, run the `preprocess_AFC_inputs.wdl` workflow to convert and index it.

### QTL File

The QTL file is a tab-separated file that must contain at minimum the following columns (as required by aFC):

| Column | Description |
|--------|-------------|
| `pid` | Phenotype (gene) ID |
| `sid` | Variant ID in the format `CHROM:POS_REF_ALT` |
| `sid_chr` | Chromosome of the variant |
| `sid_pos` | Position of the variant |

Refer to [secastel/aFC](https://github.com/secastel/aFC) for full details on the QTL file format.

> **Note:** Preprocessing of the QTL file is not included in these workflows. Because the QTL file is typically small, it was prepared outside of the pipeline using Python to ensure it contains the required columns in the correct format.

---

## Recommended Execution Order

1. **Prepare the QTL file** – Ensure it contains `pid`, `sid`, `sid_chr`, and `sid_pos` columns with variant IDs in `CHROM:POS_REF_ALT` format.
2. **Run `preprocess_AFC_inputs.wdl`** – Convert the expression BED to bgzip format and annotate VCF variant IDs (skip if your files already meet the requirements).
3. **Run `aFC.wdl`** – Use the preprocessed VCF, expression BED, covariates file, and QTL file to compute aFC values across all chromosomes.

---

## Environment

Both workflows use the Docker image `gcr.io/broad-cga-francois-gtex/gtex_eqtl:V8` (as specified in each task's `runtime` block), which provides:
- `bcftools`
- `tabix` / `bgzip`
- `Python 3` with the aFC script (`/opt/aFC/aFC.py`)

A `Dockerfile` is also provided in the `envs/` directory for reference or custom builds.

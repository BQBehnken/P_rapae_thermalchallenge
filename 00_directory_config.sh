#!/usr/bin/env bash
# 0 - here is how I set up my directory and pipeline to maintain order and method

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRAPAE_ROOT="${PRAPAE_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

GENOME_DIR="${GENOME_DIR:-${PRAPAE_ROOT}/genome_files}"
GENOME_FASTA="${GENOME_DIR}/GCF_905147795.1_ilPieRapa1.1_genomic.fna"
GENOME_GFF="${GENOME_DIR}/GCF_905147795.1_ilPieRapa1.1_genomic.gff"
STAR_INDEX="${GENOME_DIR}/STAR_index"

SAMPLE_SHEET="${PRAPAE_ROOT}/samples.csv"

THREADS="${THREADS:-36}"

RAW_DIR="${RAW_DIR:-${PRAPAE_ROOT}/01.RawData}"
TRIM_DIR="${PRAPAE_ROOT}/trim_dir"
QC_RAW_DIR="${PRAPAE_ROOT}/qc/fastqc_raw"
QC_TRIM_DIR="${PRAPAE_ROOT}/qc/fastqc_trim"
FASTP_DIR="${PRAPAE_ROOT}/qc/fastp"
ALIGN_DIR="${PRAPAE_ROOT}/align_dir"
COUNT_DIR="${COUNT_DIR:-${PRAPAE_ROOT}/counts_dir}"
MULTIQC_DIR="${MULTIQC_DIR:-${PRAPAE_ROOT}/qc/multiqc}"

RSEQC_DIR="${PRAPAE_ROOT}/qc/rseqc"  # 06-1 TIN
VIRUS_DIR="${VIRUS_DIR:-${PRAPAE_ROOT}/qc/virus}"  # 06-5 JcDNV screen

JCDNV_ACCESSION="${JCDNV_ACCESSION:-KC883978.1}"
JCDNV_EXPECTED_BASES="${JCDNV_EXPECTED_BASES:-6032}"
JCDNV_FASTA="${JCDNV_FASTA:-${GENOME_DIR}/JcDNV_${JCDNV_ACCESSION}.fna}"
JCDNV_NCBI_URL="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${JCDNV_ACCESSION}&rettype=fasta&retmode=text"

# 0a Library and strandedness
READ_LENGTH="${READ_LENGTH:-150}"
SJDB_OVERHANG=$(( READ_LENGTH - 1 ))

STRANDEDNESS="${STRANDEDNESS:-2}"

case "${STRANDEDNESS}" in
  0) STAR_COUNT_COL=2 ;;
  1) STAR_COUNT_COL=3 ;;
  2) STAR_COUNT_COL=4 ;;
  *) echo "00_config.sh: STRANDEDNESS must be 0, 1, or 2. The value is '${STRANDEDNESS}'." >&2
     return 1 2>/dev/null || exit 1 ;;
esac

# 0b Sample sheet helper
sheet_get() {
  local want="$1"
  grep -v '^#' "${SAMPLE_SHEET}" | awk -F'\t' -v want="${want}" '
    NR == 1 {
      for (i = 1; i <= NF; i++) if ($i == want) col = i
      if (col == 0) {
        print "sheet_get: the sample sheet has no column named " want > "/dev/stderr"
        exit 1
      }
      next
    }
    NF > 0 { print $col }
  '
}

sample_count() { sheet_get sample_id | wc -l | tr -d ' '; }

export SCRIPT_DIR PRAPAE_ROOT GENOME_DIR GENOME_FASTA GENOME_GFF STAR_INDEX SAMPLE_SHEET \
       THREADS RAW_DIR TRIM_DIR QC_RAW_DIR QC_TRIM_DIR FASTP_DIR ALIGN_DIR \
       COUNT_DIR MULTIQC_DIR RSEQC_DIR VIRUS_DIR \
       JCDNV_ACCESSION JCDNV_EXPECTED_BASES \
       JCDNV_FASTA JCDNV_NCBI_URL \
       READ_LENGTH SJDB_OVERHANG \
       STRANDEDNESS STAR_COUNT_COL

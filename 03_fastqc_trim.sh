#!/usr/bin/env bash
# 3 FastQC on the trimmed reads

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_config.sh"

mkdir -p "${QC_TRIM_DIR}"

files=()
while IFS=$'\t' read -r sample; do
  files+=( "${TRIM_DIR}/${sample}_1.trim.fastq.gz" "${TRIM_DIR}/${sample}_2.trim.fastq.gz" )
done < <(sheet_get sample_id)

missing=0
for f in "${files[@]}"; do
  [[ -f "${f}" ]] || { echo "03_fastqc_trim: missing ${f}" >&2; missing=1; }
done
(( missing == 0 )) || { echo "03_fastqc_trim: run 02_trim_fastp.sh first." >&2; exit 1; }

fastqc -t "${THREADS}" -o "${QC_TRIM_DIR}" "${files[@]}"

echo "03_fastqc_trim: the reports are in ${QC_TRIM_DIR}."

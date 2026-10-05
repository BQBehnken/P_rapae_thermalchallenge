#!/usr/bin/env bash
# 1 FastQC raw reads

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_config.sh"

mkdir -p "${QC_RAW_DIR}"

files=()
while IFS=$'\t' read -r r1 r2; do
  for rel in "${r1}" "${r2}"; do
    if [[ "${rel}" = /* ]]; then files+=( "${rel}" ); else files+=( "${RAW_DIR}/${rel}" ); fi
  done
done < <(paste <(sheet_get fastq_R1) <(sheet_get fastq_R2))

missing=0
for f in "${files[@]}"; do
  [[ -f "${f}" ]] || { echo "01_fastqc_raw: missing ${f}" >&2; missing=1; }
done
(( missing == 0 )) || { echo "01_fastqc_raw: run 00a_verify_md5.sh first." >&2; exit 1; }

expected=$(( $(sample_count) * 2 ))
echo "01_fastqc_raw: ${#files[@]} files for $(sample_count) samples (expected ${expected})."

fastqc -t "${THREADS}" -o "${QC_RAW_DIR}" "${files[@]}"

echo "01_fastqc_raw: the reports are in ${QC_RAW_DIR}."

#!/usr/bin/env bash
# 2 Trimming adapters and low quality reads

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_config.sh"

mkdir -p "${TRIM_DIR}" "${FASTP_DIR}"

paste <(sheet_get sample_id) <(sheet_get fastq_R1) <(sheet_get fastq_R2) \
| while IFS=$'\t' read -r sample r1 r2; do
  [[ "${r1}" = /* ]] || r1="${RAW_DIR}/${r1}"
  [[ "${r2}" = /* ]] || r2="${RAW_DIR}/${r2}"

  echo "02_trim_fastp: ${sample}"
  fastp \
    --in1 "${r1}" --in2 "${r2}" \
    --out1 "${TRIM_DIR}/${sample}_1.trim.fastq.gz" \
    --out2 "${TRIM_DIR}/${sample}_2.trim.fastq.gz" \
    --thread "${THREADS}" \
    --detect_adapter_for_pe \
    --trim_poly_g \
    --cut_right --cut_right_window_size 4 --cut_right_mean_quality 15 \
    --length_required 50 \
    --json "${FASTP_DIR}/${sample}.fastp.json" \
    --html "${FASTP_DIR}/${sample}.fastp.html"
done

echo "02_trim: the trimmed reads are in ${TRIM_DIR}."
echo "  The fastp reports are in ${FASTP_DIR}."

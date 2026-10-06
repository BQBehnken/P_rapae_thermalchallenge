#!/usr/bin/env bash
# 5 Alignment

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_config.sh"

[[ -d "${STAR_INDEX}" ]] || { echo "05_star_align: missing ${STAR_INDEX}. Run 04 first." >&2; exit 1; }

STAR_NOFILE_LIMIT=65536
current_nofile_limit="$(ulimit -Sn)"
if [[ "${current_nofile_limit}" != "unlimited" ]] &&
   (( current_nofile_limit < STAR_NOFILE_LIMIT )); then
  ulimit -Sn "${STAR_NOFILE_LIMIT}" || {
    echo "05_star_align: could not raise the open-file limit to ${STAR_NOFILE_LIMIT}." >&2
    echo "Current limits: soft=$(ulimit -Sn), hard=$(ulimit -Hn)." >&2
    exit 1
  }
fi

mkdir -p "${ALIGN_DIR}"

sheet_get sample_id | while IFS=$'\t' read -r sample; do
  [[ -n "${sample}" && "${sample}" != */* && "${sample}" != "." && "${sample}" != ".." ]] || {
    echo "05_star_align: unsafe or empty sample_id '${sample}' in ${SAMPLE_SHEET}." >&2
    exit 1
  }

  r1="${TRIM_DIR}/${sample}_1.trim.fastq.gz"
  r2="${TRIM_DIR}/${sample}_2.trim.fastq.gz"
  bam="${ALIGN_DIR}/${sample}_Aligned.sortedByCoord.out.bam"
  echo "05_star_align: ${sample}"

  rm -rf -- \
    "${ALIGN_DIR}/${sample}__STARtmp" \
    "${ALIGN_DIR}/${sample}__STARpass1" \
    "${ALIGN_DIR}/${sample}__STARgenome"
  if [[ -f "${bam}" && ! -s "${bam}" ]]; then
    rm -f -- "${bam}"
  fi

  STAR \
    --runThreadN "${THREADS}" \
    --genomeDir "${STAR_INDEX}" \
    --readFilesIn "${r1}" "${r2}" \
    --readFilesCommand zcat \
    --twopassMode Basic \
    --outSAMtype BAM SortedByCoordinate \
    --quantMode GeneCounts \
    --outSAMunmapped Within \
    --outFileNamePrefix "${ALIGN_DIR}/${sample}_"

  samtools index -@ "${THREADS}" "${bam}"
done

echo "05_star_align: the BAM files and the count files are in ${ALIGN_DIR}."

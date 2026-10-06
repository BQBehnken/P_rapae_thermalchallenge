#!/usr/bin/env bash
# 4 build STAR index

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_config.sh"

NCBI_ASSEMBLY="GCF_905147795.1_ilPieRapa1.1"
NCBI_BASE_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/905/147/795/${NCBI_ASSEMBLY}"
FASTA_GZ_MD5="232be6751688e185a8dfeab3839c8834"
GFF_GZ_MD5="ae068bdbaf83d38c2fd6f9e5ec0cbb6d"
FASTA_MD5="d7d6c550c6fb2f0665f1ac1eb67f266a"
GFF_MD5="c71965777479ec715f150f12ee88d3d8"

for program in STAR gzip awk; do
  command -v "${program}" >/dev/null 2>&1 || {
    echo "04_star_index: required program not found: ${program}" >&2
    exit 1
  }
done

if command -v md5sum >/dev/null 2>&1; then
  md5_of() { md5sum "$1" | awk '{print $1}'; }
elif command -v md5 >/dev/null 2>&1; then
  md5_of() { md5 -q "$1"; }
else
  echo "04_star_index: neither md5sum nor md5 is installed." >&2
  exit 1
fi

partial_files=()
cleanup_partial_files() {
  if (( ${#partial_files[@]} > 0 )); then
    rm -f -- "${partial_files[@]}"
  fi
}
trap cleanup_partial_files EXIT

download_file() {
  local url="$1" destination="$2" expected_gz_md5="$3" expected_md5="$4"
  local compressed="${destination}.gz.part.$$"
  local expanded="${destination}.part.$$"
  partial_files+=( "${compressed}" "${expanded}" )

  if [[ -s "${destination}" ]]; then
    if [[ "$(md5_of "${destination}")" != "${expected_md5}" ]]; then
      echo "04_star_index: existing file failed checksum: ${destination}" >&2
      echo "04_star_index: move it aside, then rerun to download a clean copy." >&2
      exit 1
    fi
    echo "04_star_index: found and verified ${destination}"
    return
  fi

  echo "04_star_index: downloading ${url}"
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --retry 5 --retry-delay 2 \
      --output "${compressed}" "${url}"
  elif command -v wget >/dev/null 2>&1; then
    wget --tries=5 --output-document="${compressed}" "${url}"
  else
    echo "04_star_index: curl or wget is required to download the reference." >&2
    exit 1
  fi

  if [[ "$(md5_of "${compressed}")" != "${expected_gz_md5}" ]]; then
    echo "04_star_index: checksum failed for ${url}" >&2
    rm -f "${compressed}"
    exit 1
  fi
  gzip -dc "${compressed}" > "${expanded}"
  if [[ "$(md5_of "${expanded}")" != "${expected_md5}" ]]; then
    echo "04_star_index: checksum failed after expanding ${url}" >&2
    rm -f "${compressed}" "${expanded}"
    exit 1
  fi
  mv "${expanded}" "${destination}"
  rm -f "${compressed}"
}

mkdir -p "${GENOME_DIR}"
download_file \
  "${NCBI_BASE_URL}/${NCBI_ASSEMBLY}_genomic.fna.gz" \
  "${GENOME_FASTA}" "${FASTA_GZ_MD5}" "${FASTA_MD5}"
download_file \
  "${NCBI_BASE_URL}/${NCBI_ASSEMBLY}_genomic.gff.gz" \
  "${GENOME_GFF}" "${GFF_GZ_MD5}" "${GFF_MD5}"

mkdir -p "${STAR_INDEX}"

STAR \
  --runMode genomeGenerate \
  --runThreadN "${THREADS}" \
  --genomeDir "${STAR_INDEX}" \
  --genomeFastaFiles "${GENOME_FASTA}" \
  --sjdbGTFfile "${GENOME_GFF}" \
  --sjdbGTFtagExonParentTranscript Parent \
  --sjdbGTFtagExonParentGene gene \
  --sjdbOverhang "${SJDB_OVERHANG}" \
  --genomeSAindexNbases 12

echo "04_star_index: the index is in ${STAR_INDEX}."

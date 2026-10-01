#!/usr/bin/env bash
# 0.2 MD5 check

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_config.sh"

if command -v md5sum >/dev/null 2>&1; then
  md5_of() { md5sum "$1" | awk '{print $1}'; }
elif command -v md5 >/dev/null 2>&1; then
  md5_of() { md5 -q "$1"; }
else
  echo "00a_verify_md5: this machine has no md5sum program and no md5 program." >&2
  exit 1
fi

n_ok=0
n_bad=0
n_missing=0

while IFS=$'\t' read -r sample r1 r2; do
  for rel in "${r1}" "${r2}" ; do
    if [[ "${rel}" = /* ]]; then file="${rel}"; else file="${RAW_DIR}/${rel}"; fi

    if [[ ! -f "${file}" ]]; then
      printf 'MISSING  %s\n' "${file}"
      n_missing=$(( n_missing + 1 ))
      continue
    fi

    base="$(basename "${file}")"
    dir="$(dirname "${file}")"
    expect=""
    if [[ -f "${dir}/MD5.txt" ]]; then
      expect="$(awk -v b="${base}" '$2 ~ b {print $1; exit}' "${dir}/MD5.txt" || true)"
    fi
    if [[ -z "${expect}" && -f "${RAW_DIR}/../MD5.txt" ]]; then
      expect="$(awk -v b="${base}" '$2 ~ b {print $1; exit}' "${RAW_DIR}/../MD5.txt" || true)"
    fi
    if [[ -z "${expect}" ]]; then
      printf 'NO CHECKSUM  %s\n' "${file}"
      n_missing=$(( n_missing + 1 ))
      continue
    fi

    got="$(md5_of "${file}")"
    if [[ "${got}" == "${expect}" ]]; then
      printf 'ok       %-14s %s\n' "${sample}" "${base}"
      n_ok=$(( n_ok + 1 ))
    else
      printf 'MISMATCH %-14s %s\n  expected %s\n  found    %s\n' \
             "${sample}" "${base}" "${expect}" "${got}"
      n_bad=$(( n_bad + 1 ))
    fi
  done
done < <(paste <(sheet_get sample_id) <(sheet_get fastq_R1) <(sheet_get fastq_R2))

echo ""
printf '00a_verify_md5: %d correct, %d different, %d missing.\n' \
       "${n_ok}" "${n_bad}" "${n_missing}"

expected_files=$(( $(sample_count) * 2 ))
if (( n_bad > 0 || n_missing > 0 )); then
  echo "00a_verify_md5: download the affected files again, then run this step again." >&2
  exit 1
fi
if (( n_ok != expected_files )); then
  echo "00a_verify_md5: the sheet has ${expected_files} files but ${n_ok} passed." >&2
  exit 1
fi
echo "00a_verify_md5: all ${n_ok} files are complete and correct."

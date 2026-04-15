#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: scripts/validate_deck.sh <deck.typ> [output-dir]" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../../../.." && pwd)"
deck_input="$1"
output_dir="${2:-/tmp/academic-paper-to-slides}"

if [[ "${deck_input}" = /* ]]; then
  deck_abs="${deck_input}"
else
  deck_abs="${repo_root}/${deck_input}"
fi

deck_dir="$(cd "$(dirname "${deck_abs}")" && pwd)"
deck_abs="${deck_dir}/$(basename "${deck_abs}")"

if [[ "${output_dir}" != /* ]]; then
  output_dir="${repo_root}/${output_dir}"
fi

mkdir -p "${output_dir}"

if [[ ! -f "${deck_abs}" ]]; then
  echo "deck not found: ${deck_input}" >&2
  exit 1
fi

case "${deck_abs}" in
  "${repo_root}"/*) ;;
  *)
    echo "deck must be inside repo root: ${repo_root}" >&2
    exit 1
    ;;
esac

deck_rel="${deck_abs#${repo_root}/}"
deck_name="$(basename "${deck_abs}" .typ)"
pdf_path="${output_dir}/${deck_name}.pdf"
preview_dir="${output_dir}/${deck_name}-pages"

echo "Compiling ${deck_rel}"
(
  cd "${repo_root}"
  typst compile --root . "${deck_rel}" "${pdf_path}"
)

echo "PDF: ${pdf_path}"

if command -v pdfinfo >/dev/null 2>&1; then
  echo "Pages: $(pdfinfo "${pdf_path}" 2>/dev/null | awk -F': *' '/^Pages:/ {print $2}')"
fi

if command -v pdftoppm >/dev/null 2>&1; then
  rm -rf "${preview_dir}"
  mkdir -p "${preview_dir}"
  pdftoppm -jpeg -r 150 "${pdf_path}" "${preview_dir}/slide" >/dev/null 2>/dev/null
  echo "Preview pages: ${preview_dir}"
else
  echo "Preview export skipped: pdftoppm not found"
fi

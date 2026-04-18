#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: scripts/validate_deck.sh <deck.typ> [output-dir]" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../../../.." && pwd)"
artifacts_script="${script_dir}/paper_artifacts.py"
review_script="${script_dir}/review_rendered_deck.py"
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
workspace_dir="${deck_dir}"
notes_dir="${workspace_dir}/notes"

echo "Compiling ${deck_rel}"
(
  cd "${repo_root}"
  typst compile --root . "${deck_rel}" "${pdf_path}"
)

echo "PDF: ${pdf_path}"

if command -v pdfinfo >/dev/null 2>&1; then
  echo "Pages: $(pdfinfo "${pdf_path}" 2>/dev/null | awk -F': *' '/^Pages:/ {print $2}')"
fi

if [[ -f "${artifacts_script}" && -d "${notes_dir}" && -f "${notes_dir}/assets.json" ]]; then
  echo "Validating JSON artifacts in ${workspace_dir}"
  (
    cd "${repo_root}"
    python3 "${artifacts_script}" validate-artifacts --workspace "${workspace_dir}"
  )
fi

if [[ -f "${review_script}" ]]; then
  review_dir="${output_dir}/review"
  review_json="${review_dir}/review.json"
  review_args=(
    python3 "${review_script}"
    "${pdf_path}"
    --output-dir "${review_dir}"
    --output-json "${review_json}"
    --fail-on error
  )
  if [[ -d "${notes_dir}" ]]; then
    review_args+=(--workspace "${workspace_dir}")
    if [[ -f "${notes_dir}/slides.json" ]]; then
      review_args+=(--slides-json "${notes_dir}/slides.json")
    fi
  fi
  echo "Reviewing rendered deck"
  (
    cd "${repo_root}"
    "${review_args[@]}"
  )
  echo "Review JSON: ${review_json}"
  echo "Page previews: ${review_dir}/pages/"
fi

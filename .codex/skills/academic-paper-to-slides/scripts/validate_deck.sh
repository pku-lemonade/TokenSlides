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
compile_metadata="${output_dir}/compile-metadata.json"

escape_slide_ids=""
if [[ -f "${notes_dir}/slides.json" ]]; then
  escape_slide_ids="$(
    python3 - "${notes_dir}/slides.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    slides = json.load(handle).get("slides", [])

ids = []
for index, slide in enumerate(slides, start=1):
    if not isinstance(slide, dict):
        continue
    render_mode = str(slide.get("render_mode", "script")).strip().lower()
    if render_mode == "escape":
        ids.append(slide.get("slide_id") or f"slide-{index:02d}")

print("|".join(ids))
PY
  )"
fi

compiled_deck_abs="${deck_abs}"
compiled_deck_rel="${deck_rel}"

write_compile_metadata() {
  python3 - "$compile_metadata" "$deck_abs" "$compiled_deck_abs" "$1" "$escape_slide_ids" <<'PY'
import json
import sys
from pathlib import Path

out_path = Path(sys.argv[1])
payload = {
    "original_deck_typ": sys.argv[2],
    "compiled_deck_typ": sys.argv[3],
    "escape_fallback_used": sys.argv[4].lower() == "true",
    "escape_fallback_slide_ids": [item for item in sys.argv[5].split("|") if item],
}
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY
}

echo "Compiling ${deck_rel}"
if ! (
  cd "${repo_root}"
  typst compile --root . "${deck_rel}" "${pdf_path}"
); then
  if [[ -n "${escape_slide_ids}" && -f "${artifacts_script}" && -f "${notes_dir}/slides.json" ]]; then
    fallback_deck_abs="${workspace_dir}/${deck_name}.escape-fallback.typ"
    fallback_deck_rel="${fallback_deck_abs#${repo_root}/}"
    echo "Compile failed; retrying with escape disabled"
    (
      cd "${repo_root}"
      python3 "${artifacts_script}" emit-deck --workspace "${workspace_dir}" --out "${fallback_deck_abs}" --disable-escape
      typst compile --root . "${fallback_deck_rel}" "${pdf_path}"
    )
    compiled_deck_abs="${fallback_deck_abs}"
    compiled_deck_rel="${fallback_deck_rel}"
    write_compile_metadata "true"
  else
    exit 1
  fi
else
  write_compile_metadata "false"
fi

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
    --compile-metadata "${compile_metadata}"
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

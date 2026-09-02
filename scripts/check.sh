#!/usr/bin/env bash
# Compile every example deck (and, with --out, every deck under out/) from the
# repository root. Fails on the first Typst error. Usage:
#   scripts/check.sh          # examples/ only
#   scripts/check.sh --out    # examples/ plus decks under out/
#   scripts/check.sh --png DIR   # also render PNG pages into DIR/<deck>/ for diffing
#   scripts/check.sh --diff DIR  # render and compare page-by-page against a --png DIR
#   scripts/check.sh --coverage  # every public theme name must appear in a docs/ deck
set -euo pipefail
cd "$(dirname "$0")/.."

with_out=0
png_dir=""
ref_dir=""
while [ $# -gt 0 ]; do
    case "$1" in
        --out) with_out=1 ;;
        --png) png_dir="$2"; shift ;;
        --diff) ref_dir="$2"; shift ;;
        --coverage) exec python3 scripts/coverage.py ;;
        *) echo "unknown flag: $1" >&2; exit 2 ;;
    esac
    shift
done

# A deck is a .typ file that applies the theme; component files are skipped.
roots=(docs examples)
if [ "$with_out" = 1 ] && [ -d out ]; then roots+=(out); fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if [ -n "$ref_dir" ] && [ -z "$png_dir" ]; then png_dir="$tmp/png"; fi
failed=0
warned=0
count=0
changed=0
while IFS= read -r src; do
    count=$((count + 1))
    name=$(basename "${src%.typ}")
    if typst compile --root . "$src" "$tmp/$name.pdf" >"$tmp/$name.log" 2>&1; then
        if grep -q '^warning' "$tmp/$name.log"; then
            warned=$((warned + 1))
            printf 'WARN %s\n' "$src"
            grep -A2 '^warning' "$tmp/$name.log" | sed 's/^/     /'
        else
            printf 'ok   %s\n' "$src"
        fi
        if [ -n "$png_dir" ]; then
            mkdir -p "$png_dir/$name"
            typst compile --root . --format png --ppi 48 "$src" "$png_dir/$name/{0p}.png" >/dev/null 2>&1
            if [ -n "$ref_dir" ]; then
                if [ ! -d "$ref_dir/$name" ]; then
                    printf '     new deck, no reference\n'
                elif ! diff -rq "$ref_dir/$name" "$png_dir/$name" >"$tmp/$name.diff"; then
                    changed=$((changed + 1))
                    printf '     CHANGED pages: %s\n' "$(sed -E 's/.*\/([0-9]+)\.png.*/\1/' "$tmp/$name.diff" | sort -n | tr '\n' ' ')"
                fi
            fi
        fi
    else
        failed=$((failed + 1))
        printf 'FAIL %s\n' "$src"
        sed 's/^/     /' "$tmp/$name.log"
    fi
done < <(grep -rl --include='*.typ' --exclude-dir=archive 'lemonade-theme.with' "${roots[@]}")
echo "$count decks, $failed failed, $warned with warnings${ref_dir:+, $changed changed vs $ref_dir}"
[ "$failed" = 0 ] && [ "$warned" = 0 ]

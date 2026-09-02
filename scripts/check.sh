#!/usr/bin/env bash
# Compile every example deck (and, with --out, every deck under out/) from the
# repository root. Fails on the first Typst error. Usage:
#   scripts/check.sh          # examples/ only
#   scripts/check.sh --out    # examples/ plus decks under out/
#   scripts/check.sh --png DIR  # also render PNG pages into DIR/<deck>/ for diffing
set -euo pipefail
cd "$(dirname "$0")/.."

with_out=0
png_dir=""
while [ $# -gt 0 ]; do
    case "$1" in
        --out) with_out=1 ;;
        --png) png_dir="$2"; shift ;;
        *) echo "unknown flag: $1" >&2; exit 2 ;;
    esac
    shift
done

# A deck is a .typ file that applies the theme; component files are skipped.
roots=(examples)
if [ "$with_out" = 1 ] && [ -d out ]; then roots+=(out); fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0
count=0
while IFS= read -r src; do
    count=$((count + 1))
    name=$(basename "${src%.typ}")
    if typst compile --root . "$src" "$tmp/$name.pdf" >"$tmp/$name.log" 2>&1; then
        printf 'ok   %s\n' "$src"
        if [ -n "$png_dir" ]; then
            mkdir -p "$png_dir/$name"
            typst compile --root . --format png --ppi 48 "$src" "$png_dir/$name/{0p}.png" >/dev/null 2>&1
        fi
    else
        failed=$((failed + 1))
        printf 'FAIL %s\n' "$src"
        sed 's/^/     /' "$tmp/$name.log"
    fi
done < <(grep -rl --include='*.typ' --exclude-dir=archive 'lemonade-theme.with' "${roots[@]}")
echo "$count decks, $failed failed"
[ "$failed" = 0 ]

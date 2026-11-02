#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/~mf-cloner-config/shared.sh"

cd "$(dirname "$0")"

merged=()
while IFS=$'\t' read -r _ dir branch pr state; do
  [ "$dir" != ./root ] || continue
  if [ "$state" = merged ]; then
    echo "$dir  ($branch, PR #$pr merged)"
    merged+=("$dir")
  else
    echo "keep: $dir  ($branch)"
  fi
done < <(scan_clones)

if [ ${#merged[@]} -eq 0 ]; then
  echo "Nothing to remove."
  exit 0
fi

if [ "${1:-}" != "-y" ]; then
  read -rp "Remove ${#merged[@]} folder(s)? [y/N] " answer
  [ "$answer" = "y" ] || exit 0
fi

for dir in "${merged[@]}"; do
  [ -d "$dir" ] || continue
  rm -rf "$dir"
  # Drop parents left empty by branch names like lz/fix/foo
  # (stops at the first non-empty one; macOS rmdir has no --ignore-fail-on-non-empty)
  rmdir -p "$(dirname "$dir")" 2>/dev/null || true
  echo "Removed $dir"
done

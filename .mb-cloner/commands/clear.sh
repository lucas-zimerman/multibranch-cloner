# mb clear [-y]: removes the clones whose PR was merged.
cmd_clear() {
  local merged=() dir branch pr state answer

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
    return 0
  fi

  if [ "${1:-}" != "-y" ]; then
    read -rp "Remove ${#merged[@]} folder(s)? [y/N] " answer
    [ "$answer" = "y" ] || return 0
  fi

  for dir in "${merged[@]}"; do
    [ -d "$dir" ] || continue
    rm -rf "$dir"
    # Drop parents left empty by branch names like lz/fix/foo
    # (stops at the first non-empty one; macOS rmdir has no --ignore-fail-on-non-empty)
    rmdir -p "$(dirname "$dir")" 2>/dev/null || true
    echo "Removed $dir"
  done
}

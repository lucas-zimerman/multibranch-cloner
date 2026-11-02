# mb update [-y]: downloads the latest scripts, shows what changed and asks before applying.
# Never touches data.sh or env.local.sh.
cmd_update() {
  command -v curl >/dev/null || { echo "Error: curl is required" >&2; return 1; }

  local tmp f var
  tmp=$(mktemp -d)

  mkdir -p "$tmp/.mb-cloner"
  curl -fsSL "$mb_base_url/.mb-cloner/manifest" -o "$tmp/.mb-cloner/manifest" \
    || { echo "Error: could not download the manifest from $mb_base_url" >&2; rm -rf "$tmp"; return 1; }

  local files=() changed=()
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    files+=("$f")
    mkdir -p "$tmp/$(dirname "$f")"
    curl -fsSL "$mb_base_url/$f" -o "$tmp/$f" \
      || { echo "Error: failed to download $f" >&2; rm -rf "$tmp"; return 1; }
    if [ ! -e "$root/$f" ]; then
      echo "new:     $f"
      changed+=("$f")
    elif ! cmp -s "$root/$f" "$tmp/$f"; then
      echo "changed: $f"
      changed+=("$f")
    fi
  done < "$tmp/.mb-cloner/manifest"

  if [ ${#changed[@]} -eq 0 ]; then
    echo "Already up to date."
  else
    echo
    for f in "${changed[@]}"; do
      [ -e "$root/$f" ] && diff -u "$root/$f" "$tmp/$f" || true
    done

    if [ "${1:-}" != "-y" ]; then
      local answer
      read -rp "Apply ${#changed[@]} change(s)? [y/N] " answer
      [ "$answer" = "y" ] || { rm -rf "$tmp"; return 0; }
    fi

    for f in "${changed[@]}"; do
      mkdir -p "$root/$(dirname "$f")"
      # Copy + rename instead of overwriting in place, so a running script keeps its old file
      cp "$tmp/$f" "$root/$f.new"
      case "$f" in mb|*.sh) chmod +x "$root/$f.new" ;; esac
      mv "$root/$f.new" "$root/$f"
    done
    echo "Updated."
  fi
  rm -rf "$tmp"

  # Warn about variables that data.example.sh has and data.sh lacks
  while IFS= read -r var; do
    grep -q "^$var=" "$lib/data.sh" 2>/dev/null \
      || echo "Warning: data.sh is missing '$var' (see .mb-cloner/data.example.sh)" >&2
  done < <(sed -n 's/^\([a-z_][a-z_0-9]*\)=.*/\1/p' "$lib/data.example.sh")
}

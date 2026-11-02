#!/usr/bin/env bash
# Generates data.sh from data.example.sh by asking for each value.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
example="$dir/data.example.sh"
target="$dir/data.sh"

if [ -e "$target" ]; then
  read -r -p "data.sh already exists. Overwrite? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted." >&2; exit 1; }
fi

cp "$example" "$target"

# Replaces the value of a variable in data.sh (value is passed via env, so no escaping issues).
set_var() {
  local tmp
  tmp=$(mktemp)
  VAR="$1" VAL="$2" awk '
    BEGIN { var = ENVIRON["VAR"]; val = ENVIRON["VAL"]; gsub(/[\\"$`]/, "\\\\&", val) }
    index($0, var "=") == 1 { print var "=\"" val "\""; next }
    { print }
  ' "$target" > "$tmp"
  mv "$tmp" "$target"
}

# ask <prompt> -> prints the non-empty answer
ask() {
  local value=""
  while [ -z "$value" ]; do
    read -r -p "$1: " value
  done
  printf '%s' "$value"
}

while true; do
  repo=$(ask "Repo (username/reponame)")
  [[ "$repo" =~ ^[^/[:space:]]+/[^/[:space:]]+$ ]] && break
  echo "Expected format: username/reponame" >&2
done
set_var repo "$repo"

set_var tab_title_prefix "$(ask "Tab title")"

echo "Tab color:"
colors=(red green blue yellow orange purple cyan magenta pink brown gray "other (type your own)")
select choice in "${colors[@]}"; do
  [ -n "$choice" ] || continue
  if [[ "$choice" == other* ]]; then
    choice=$(ask "Color (name or #rrggbb)")
  fi
  set_var tab_color "$choice"
  break
done

set_var git_name "$(ask "Git name")"
set_var git_email "$(ask "Git email")"
set_var agent_name "$(ask "Agent name (e.g. Claude)")"
set_var agent_invoke_name "$(ask "Command to invoke the agent (e.g. claude)")"

echo "Wrote $target"

# Generate env.local.sh from env.example.sh (holds post_clone_setup), add the Konsole loader if needed, and load it
env_local="$dir/env.local.sh"
if [ -e "$env_local" ]; then
  echo "env.local.sh already exists, keeping it."
else
  cp "$dir/env.example.sh" "$env_local"
  echo "Wrote $env_local"
fi
if [ -n "${KONSOLE_DBUS_SESSION:-}" ] && ! grep -q 'kde/konsole.sh' "$env_local"; then
  printf '\nsource "$(dirname "${BASH_SOURCE[0]}")/kde/konsole.sh"\n' >> "$env_local"
  echo "Added kde/konsole.sh to env.local.sh"
fi
# shellcheck source=/dev/null
source "$env_local"

# Final instructions: a prompt for the user to give to their agent
source "$target"
cat <<PROMPT

Installation finished. Next, open ${agent_name} in this folder and give it this prompt:

------------------------------------------------------------
Analyse the repository ${repo_url} and work out the steps needed after cloning
it so the project is ready to start working (toolchain/version managers,
dependency install, bootstrap, git hooks, code generation, ...).

Then add the following function to $dir/env.local.sh (replacing the
placeholder if it is already there) and fill it with those steps:

post_clone_setup() {
  :
}

The function runs inside the freshly cloned folder, so use relative commands.
Keep it idempotent and add a short comment above each step.
------------------------------------------------------------
PROMPT

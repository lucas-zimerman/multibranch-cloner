# mb open <folder>: starts the agent inside an existing clone.
cmd_open() {
  if [ $# -ne 1 ]; then
    echo "Usage: mb open <folder>" >&2
    return 1
  fi

  local target="$1"

  if [ ! -d "$target" ]; then
    echo "Error: '$target' does not exist" >&2
    return 1
  fi

  set_tab "$target"

  cd "$target"

  exec "$agent_invoke_name"
}

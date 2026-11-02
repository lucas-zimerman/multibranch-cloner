#!/usr/bin/env -S bash -i
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/~mf-cloner-config/shared.sh"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <folder>" >&2
  exit 1
fi

target="$1"

if [ ! -d "$target" ]; then
  echo "Error: '$target' does not exist" >&2
  exit 1
fi

set_tab "$target"

cd "$target"

exec "$agent_invoke_name"

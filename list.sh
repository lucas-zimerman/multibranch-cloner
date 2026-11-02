#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/~mf-cloner-config/shared.sh"

cd "$(dirname "$0")"

{
  echo "LAST ACCESS	FOLDER	BRANCH	PR"
  scan_clones | sort -rn | while IFS=$'\t' read -r last dir branch pr state; do
    [ "$pr" = - ] || pr="#$pr $state"
    echo "$(format_epoch "$last" '+%Y-%m-%d %H:%M')	$dir	$branch	$pr"
  done
} | column -t -s $'\t'

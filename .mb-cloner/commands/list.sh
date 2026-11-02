# mb list: shows every clone with its last access time, branch and PR.
cmd_list() {
  {
    echo "LAST ACCESS	FOLDER	BRANCH	PR"
    scan_clones | sort -rn | while IFS=$'\t' read -r last dir branch pr state; do
      [ "$pr" = - ] || pr="#$pr $state"
      echo "$(format_epoch "$last" '+%Y-%m-%d %H:%M')	$dir	$branch	$pr"
    done
  } | column -t -s $'\t'
}

# mb: multibranch cloner (Windows / PowerShell). One full clone per branch/task, each with its own agent session.
# Counterpart of the `mb` bash script; both can live in the same folder.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$lib  = Join-Path $root '.mb-cloner'

function Show-Usage {
  @'
Usage: mb <command> [args]

Commands:
  clone <folder>   Clone the repo into <folder> on a branch named <folder>, then start the agent
  open <folder>    Start the agent inside an existing clone
  list             List clones with last access, branch and PR
  clear [-y]       Remove clones whose PR was merged
  update [-y]      Download the latest version of these scripts
'@
}

$cmd = if ($args.Count -gt 0) { [string]$args[0] } else { '' }
$rest = @(if ($args.Count -gt 1) { $args[1..($args.Count - 1)] })

switch -Regex ($cmd) {
  '^(clone|open|list|clear|update)$' { break }
  '^(|-h|--help|help)$' { Show-Usage; exit 0 }
  default { [Console]::Error.WriteLine("Unknown command: $cmd"); Show-Usage; exit 1 }
}

if ($cmd -ne 'update' -and -not (Test-Path (Join-Path $lib 'data.ps1'))) {
  [Console]::Error.WriteLine("Not configured yet. Run: $lib\install.ps1")
  exit 1
}

. (Join-Path $lib 'shared.ps1')
. (Join-Path $lib "commands\$cmd.ps1")

# Clones live next to this script
Set-Location $root

& "Invoke-Mb$($cmd.Substring(0,1).ToUpper() + $cmd.Substring(1))" @rest

# Generates data.ps1 from data.example.ps1 by asking for each value (Windows / PowerShell).
#
# Remote install (run it in the folder where your clones should live):
#   irm https://raw.githubusercontent.com/lucas-zimerman/multibranch-cloner/main/.mb-cloner/install.ps1 | iex
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$baseUrl = if ($env:MB_CLONER_URL) { $env:MB_CLONER_URL } else { 'https://raw.githubusercontent.com/lucas-zimerman/multibranch-cloner/main' }
$configDirname = '.mb-cloner'

$dir = if ($PSScriptRoot) { $PSScriptRoot } else { $null }

# Not running from a checkout of the repo (irm | iex): download the files into the current folder
if (-not $dir -or -not (Test-Path (Join-Path $dir 'data.example.ps1'))) {
  Write-Host "Downloading mb-cloner into $PWD ..."
  New-Item -ItemType Directory -Force -Path $configDirname | Out-Null
  try { Invoke-WebRequest -UseBasicParsing "$baseUrl/$configDirname/manifest.windows" -OutFile "$configDirname\manifest.windows" }
  catch { throw "Failed to download the manifest from $baseUrl" }
  foreach ($f in (Get-Content "$configDirname\manifest.windows" | Where-Object { $_ })) {
    $rel = $f -replace '/', '\'
    $parent = Split-Path -Parent $rel
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    try { Invoke-WebRequest -UseBasicParsing "$baseUrl/$f" -OutFile $rel }
    catch { throw "Failed to download $f" }
  }
  $dir = Join-Path $PWD $configDirname
}

$example = Join-Path $dir 'data.example.ps1'
$target  = Join-Path $dir 'data.ps1'

if (Test-Path $target) {
  $answer = Read-Host 'data.ps1 already exists. Overwrite? [y/N]'
  if ($answer -notmatch '^[Yy]$') { Write-Host 'Aborted.'; exit 1 }
}

Copy-Item $example $target -Force

# Replaces the value of a variable in data.ps1 (single-quoted, so no escaping issues besides ').
function Set-Var([string]$Name, [string]$Value) {
  $escaped = $Value -replace "'", "''"
  $prefix = '$' + $Name
  $lines = Get-Content $target | ForEach-Object {
    if ($_ -match ('^' + [regex]::Escape($prefix) + '\s*=')) { "$prefix = '$escaped'" } else { $_ }
  }
  Set-Content -Path $target -Value $lines -Encoding UTF8
}

# Ask <prompt> -> the non-empty answer
function Ask([string]$Prompt) {
  $value = ''
  while (-not $value) { $value = (Read-Host $Prompt).Trim() }
  $value
}

while ($true) {
  $repo = Ask 'Repo (username/reponame)'
  if ($repo -match '^[^/\s]+/[^/\s]+$') { break }
  Write-Host 'Expected format: username/reponame' -ForegroundColor Red
}
Set-Var repo $repo

Set-Var tab_title_prefix (Ask 'Tab title')

$colors = 'red','green','blue','yellow','orange','purple','cyan','magenta','pink','brown','gray','other (type your own)'
Write-Host 'Tab color (stored for parity with Linux; Windows Terminal tab colors are not scriptable):'
for ($i = 0; $i -lt $colors.Count; $i++) { Write-Host ('{0,2}) {1}' -f ($i + 1), $colors[$i]) }
do { $n = 0; [void][int]::TryParse((Read-Host '#?'), [ref]$n) } until ($n -ge 1 -and $n -le $colors.Count)
$choice = $colors[$n - 1]
if ($choice -like 'other*') { $choice = Ask 'Color (name or #rrggbb)' }
Set-Var tab_color $choice

Set-Var git_name (Ask 'Git name')
Set-Var git_email (Ask 'Git email')
Set-Var agent_name (Ask 'Agent name (e.g. Claude)')
Set-Var agent_invoke_name (Ask 'Command to invoke the agent (e.g. claude)')

Write-Host "Wrote $target"

# Generate env.local.ps1 from env.example.ps1 (holds post_clone_setup)
$envLocal = Join-Path $dir 'env.local.ps1'
if (Test-Path $envLocal) {
  Write-Host 'env.local.ps1 already exists, keeping it.'
} else {
  Copy-Item (Join-Path $dir 'env.example.ps1') $envLocal
  Write-Host "Wrote $envLocal"
}

# Final instructions: a prompt for the user to give to their agent
. $target
@"

Installation finished. Next, open $agent_name in this folder and give it this prompt:

------------------------------------------------------------
Analyse the repository $repo_url and work out the steps needed after cloning
it so the project is ready to start working (toolchain/version managers,
dependency install, bootstrap, git hooks, code generation, ...).

Then add the following function to $envLocal (replacing the
placeholder if it is already there) and fill it with those steps (PowerShell):

function post_clone_setup {
}

The function runs inside the freshly cloned folder, so use relative commands.
Keep it idempotent and add a short comment above each step.
------------------------------------------------------------

Then start working with:
  ./mb clone <folder>     (see ./mb help)
"@ | Write-Host

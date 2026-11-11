# mb update [-y]: downloads the latest Windows scripts, shows what changed and asks before applying.
# Never touches data.ps1 or env.local.ps1. (The Linux/macOS files are updated by `./mb update`.)
function Invoke-MbUpdate {
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ('mb-update-' + [guid]::NewGuid())
  New-Item -ItemType Directory -Path $tmp | Out-Null
  $ProgressPreference = 'SilentlyContinue'
  $yes = $args[0] -eq '-y'

  function Get-Remote([string]$Rel) {
    $dest = Join-Path $tmp $Rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
    Invoke-WebRequest -UseBasicParsing -Uri "$mb_base_url/$($Rel -replace '\\','/')" -OutFile $dest
    $dest
  }

  try {
    try { $manifest = Get-Remote '.mb-cloner\manifest.windows' }
    catch { [Console]::Error.WriteLine("Error: could not download the manifest from $mb_base_url"); return }

    $changed = @()
    foreach ($f in (Get-Content $manifest | Where-Object { $_ })) {
      $rel = $f -replace '/', '\'
      try { $new = Get-Remote $rel }
      catch { [Console]::Error.WriteLine("Error: failed to download $f"); return }
      $local = Join-Path $root $rel
      if (-not (Test-Path -LiteralPath $local)) {
        Write-Host "new:     $f"; $changed += $rel
      } elseif ((Get-FileHash $local).Hash -ne (Get-FileHash $new).Hash) {
        Write-Host "changed: $f"; $changed += $rel
      }
    }

    if ($changed.Count -eq 0) {
      Write-Host 'Already up to date.'
    } else {
      Write-Host ''
      foreach ($rel in $changed) {
        $local = Join-Path $root $rel
        if (Test-Path -LiteralPath $local) {
          Write-Host "--- $rel"
          Compare-Object (Get-Content $local) (Get-Content (Join-Path $tmp $rel)) | ForEach-Object {
            $sign = if ($_.SideIndicator -eq '=>') { '+' } else { '-' }
            Write-Host "$sign $($_.InputObject)"
          }
        }
      }

      if (-not $yes) {
        $answer = Read-Host "Apply $($changed.Count) change(s)? [y/N]"
        if ($answer -ne 'y') { return }
      }

      foreach ($rel in $changed) {
        $local = Join-Path $root $rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $local) | Out-Null
        # Copy + rename instead of overwriting in place, so a running script keeps its old file
        Copy-Item (Join-Path $tmp $rel) "$local.new" -Force
        Move-Item "$local.new" $local -Force
      }
      Write-Host 'Updated.'
    }

    # Warn about variables that data.example.ps1 has and data.ps1 lacks
    $dataFile = Join-Path $mb_lib 'data.ps1'
    $have = if (Test-Path $dataFile) { Get-Content $dataFile -Raw } else { '' }
    $exampleText = Get-Content (Join-Path $mb_lib 'data.example.ps1') -Raw
    foreach ($m in [regex]::Matches($exampleText, '(?m)^\$([a-z_][a-z_0-9]*)\s*=')) {
      $var = $m.Groups[1].Value
      if ($have -notmatch ('(?m)^\$' + $var + '\s*=')) {
        [Console]::Error.WriteLine("Warning: data.ps1 is missing '$var' (see .mb-cloner/data.example.ps1)")
      }
    }
  } finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}

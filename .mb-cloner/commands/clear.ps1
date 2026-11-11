# mb clear [-y]: removes the clones whose PR was merged.
function Invoke-MbClear {
  $merged = @()
  foreach ($c in Get-Clones) {
    if ($c.State -eq 'merged') {
      Write-Host "$($c.Dir)  ($($c.Branch), PR #$($c.Pr) merged)"
      $merged += $c.Dir
    } else {
      Write-Host "keep: $($c.Dir)  ($($c.Branch))"
    }
  }

  if ($merged.Count -eq 0) {
    Write-Host 'Nothing to remove.'
    return
  }

  if ($args[0] -ne '-y') {
    $answer = Read-Host "Remove $($merged.Count) folder(s)? [y/N]"
    if ($answer -ne 'y') { return }
  }

  foreach ($dir in $merged) {
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    # Git marks pack files read-only, which makes Remove-Item fail on Windows
    Get-ChildItem -LiteralPath $dir -Recurse -Force -File -ErrorAction SilentlyContinue |
      Where-Object { $_.IsReadOnly } | ForEach-Object { $_.IsReadOnly = $false }
    Remove-Item -LiteralPath $dir -Recurse -Force
    # Drop parents left empty by branch names like lz/fix/foo
    $parent = Split-Path -Parent $dir
    while ($parent -and $parent -ne '.' -and (Test-Path -LiteralPath $parent) -and
           -not (Get-ChildItem -LiteralPath $parent -Force)) {
      Remove-Item -LiteralPath $parent -Force
      $parent = Split-Path -Parent $parent
    }
    Write-Host "Removed $dir"
  }
}

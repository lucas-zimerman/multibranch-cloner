# mb list: shows every clone with its last access time, branch and PR.
function Invoke-MbList {
  $rows = @(Get-Clones | Sort-Object Last -Descending | ForEach-Object {
    [pscustomobject][ordered]@{
      'LAST ACCESS' = $_.Last.ToString('yyyy-MM-dd HH:mm')
      FOLDER        = $_.Dir
      BRANCH        = $_.Branch
      PR            = if ($_.Pr -eq '-') { '-' } else { "#$($_.Pr) $($_.State)" }
    }
  })
  if ($rows.Count -eq 0) { Write-Host 'No clones found.'; return }
  $rows | Format-Table -AutoSize | Out-String -Width 4096 | Write-Host
}

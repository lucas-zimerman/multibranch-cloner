# mb clone <folder>: clones the repo into <folder>, on a branch named <folder>, then starts the agent.
function Invoke-MbClone {
  if ($args.Count -ne 1) {
    [Console]::Error.WriteLine('Usage: mb clone <folder>')
    exit 1
  }
  $target = [string]$args[0]

  if (Test-Path -LiteralPath $target) {
    [Console]::Error.WriteLine("Error: '$target' already exists")
    exit 1
  }

  Set-Tab $target

  Invoke-Git clone $repo_url $target
  Set-Location $target
  Invoke-Git config user.name $git_name
  Invoke-Git config user.email $git_email

  # Continues the branch if it was pushed from another machine, else starts it from the remote default branch
  & git ls-remote --exit-code --heads origin $target *> $null
  if ($LASTEXITCODE -eq 0) {
    Invoke-Git checkout $target
  } else {
    # origin/HEAD is set by clone; fall back to asking the remote
    $default = (& git symbolic-ref --short refs/remotes/origin/HEAD 2>$null) -join ''
    if (-not $default) {
      $line = & git ls-remote --symref origin HEAD | Where-Object { $_ -like 'ref:*' } | Select-Object -First 1
      $default = 'origin/' + (($line -split '\s+')[1] -replace '^refs/heads/', '')
    }
    Invoke-Git checkout -b $target $default
  }

  # Repo-specific setup; defined in env.local.ps1 (see env.example.ps1)
  if (Get-Command post_clone_setup -CommandType Function -ErrorAction SilentlyContinue) { post_clone_setup }

  & $agent_invoke_name
}

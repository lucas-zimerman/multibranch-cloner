# mb open <folder>: starts the agent inside an existing clone.
function Invoke-MbOpen {
  if ($args.Count -ne 1) {
    [Console]::Error.WriteLine('Usage: mb open <folder>')
    exit 1
  }
  $target = [string]$args[0]

  if (-not (Test-Path -LiteralPath $target -PathType Container)) {
    [Console]::Error.WriteLine("Error: '$target' does not exist")
    exit 1
  }

  Set-Tab $target
  Set-Location $target

  & $agent_invoke_name
}

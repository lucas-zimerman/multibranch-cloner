# Sets the terminal tab title (Windows Terminal, conhost, VS Code terminal).
# The tab color can't be set from a script in Windows Terminal; configure it per profile instead.
function Set-TerminalTabHeader([string]$Title) {
  # Stop Claude Code from overwriting the tab title set below.
  $env:CLAUDE_CODE_DISABLE_TERMINAL_TITLE = '1'
  try { $Host.UI.RawUI.WindowTitle = $Title } catch { }
}

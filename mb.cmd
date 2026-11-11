@echo off
rem mb (Windows launcher): forwards to mb.ps1 in PowerShell.
where pwsh >nul 2>nul && (set "MB_PS=pwsh") || (set "MB_PS=powershell")
%MB_PS% -NoProfile -ExecutionPolicy Bypass -File "%~dp0mb.ps1" %*
exit /b %ERRORLEVEL%

@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0Install MIDI Effect.ps1" (
  echo Extract the whole Spektrafilm MIDI ZIP before installing.
  echo.
  pause
  exit /b 1
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install MIDI Effect.ps1"
exit /b %errorlevel%

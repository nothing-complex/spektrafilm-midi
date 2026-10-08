@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0companion\SpektrafilmMidi.exe" (
  echo Extract the whole Spektrafilm MIDI ZIP before starting the app.
  echo Keep this launcher beside the companion and profiles folders.
  echo.
  pause
  exit /b 1
)
start "" "%~dp0companion\SpektrafilmMidi.exe" --profiles "%~dp0profiles"

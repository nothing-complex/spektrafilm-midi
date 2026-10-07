@echo off
setlocal EnableExtensions

set "SOURCE_DIR=%~dp0"
if "%SOURCE_DIR:~-1%"=="\" set "SOURCE_DIR=%SOURCE_DIR:~0,-1%"

if defined CommonProgramW6432 (
  set "OFX_ROOT=%CommonProgramW6432%\OFX\Plugins"
) else (
  set "OFX_ROOT=%CommonProgramFiles%\OFX\Plugins"
)

net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo Requesting administrator permission to install into:
  echo   %OFX_ROOT%
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -WorkingDirectory '%~dp0' -Verb RunAs"
  exit /b
)

if not exist "%SOURCE_DIR%\spektrafilm_flow.ofx.bundle\Contents\Win64\spektrafilm_flow.ofx" (
  echo Missing spektrafilm_flow.ofx.bundle next to install.bat.
  pause
  exit /b 1
)

if not exist "%SOURCE_DIR%\spektrafilm.ofx.bundle\Contents\Win64\spektrafilm.ofx" (
  echo Missing spektrafilm.ofx.bundle next to install.bat.
  pause
  exit /b 1
)

echo Installing spektrafilm OFX into:
echo   %OFX_ROOT%
echo.

mkdir "%OFX_ROOT%" >nul 2>&1

if exist "%OFX_ROOT%\spektrafilm_flow.ofx.bundle" (
  echo Removing old spektrafilm flow bundle...
  rmdir /s /q "%OFX_ROOT%\spektrafilm_flow.ofx.bundle"
)

if exist "%OFX_ROOT%\spektrafilm.ofx.bundle" (
  echo Removing old spektrafilm bundle...
  rmdir /s /q "%OFX_ROOT%\spektrafilm.ofx.bundle"
)

echo Copying spektrafilm flow...
robocopy "%SOURCE_DIR%\spektrafilm_flow.ofx.bundle" "%OFX_ROOT%\spektrafilm_flow.ofx.bundle" /E /NFL /NDL /NJH /NJS /NP
if %errorlevel% GEQ 8 (
  echo Failed to copy spektrafilm_flow.ofx.bundle.
  pause
  exit /b 1
)

echo Copying spektrafilm...
robocopy "%SOURCE_DIR%\spektrafilm.ofx.bundle" "%OFX_ROOT%\spektrafilm.ofx.bundle" /E /NFL /NDL /NJH /NJS /NP
if %errorlevel% GEQ 8 (
  echo Failed to copy spektrafilm.ofx.bundle.
  pause
  exit /b 1
)

echo.
echo Installed both spektrafilm OFX plugins.
echo Restart your OFX host application so it rescans the plugin folder.
pause

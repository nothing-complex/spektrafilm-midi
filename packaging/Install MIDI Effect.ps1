[CmdletBinding()]
param([switch]$Elevated)
$ErrorActionPreference='Stop'

function Finish-Installer([int]$Result) {
  Write-Host ''
  Read-Host 'Press Enter to close this installer' | Out-Null
  exit $Result
}

Write-Host 'Spektrafilm MIDI - one-time effect installation' -ForegroundColor Cyan
Write-Host ''
if (Get-Process Resolve -ErrorAction SilentlyContinue) {
  Write-Host 'Close DaVinci Resolve, then run Install MIDI Effect.cmd again.' -ForegroundColor Yellow
  Write-Host 'Your Resolve session has been left open.'
  Finish-Installer 1
}

$installer=Join-Path $PSScriptRoot 'Install.ps1'
$bundleManifest=Join-Path $PSScriptRoot 'spektrafilm_midi.ofx.bundle/Contents/Resources/plugin_manifest.json'
if (-not (Test-Path -LiteralPath $installer) -or -not (Test-Path -LiteralPath $bundleManifest)) {
  Write-Host 'Extract the whole release ZIP before installing.' -ForegroundColor Yellow
  Write-Host 'Keep this launcher beside Install.ps1 and spektrafilm_midi.ofx.bundle.'
  Finish-Installer 1
}

$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$principal=New-Object Security.Principal.WindowsPrincipal($identity)
$isAdministrator=$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdministrator) {
  if ($Elevated) {
    Write-Host 'Administrator access is needed to copy the effect into the system OFX folder.' -ForegroundColor Yellow
    Finish-Installer 1
  }
  Write-Host 'Windows will ask permission to install the effect in the OFX plugins folder.'
  try {
    $powershell=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $arguments='-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '" -Elevated'
    # This is the installer window the user explicitly opened, with visible results.
    $child=Start-Process -FilePath $powershell -ArgumentList $arguments -Verb RunAs -WindowStyle Normal -Wait -PassThru
    exit $child.ExitCode
  } catch {
    Write-Host 'Installation was not started. Run the installer again and approve the Windows permission prompt.' -ForegroundColor Yellow
    Write-Host $_.Exception.Message
    Finish-Installer 1
  }
}

try {
  & $installer -Apply
  Write-Host ''
  Write-Host 'Done. Open Resolve and add Spektrafilm MIDI (Community Beta) to a node.' -ForegroundColor Green
  Write-Host 'Then run Start Spektrafilm MIDI.cmd to connect your panels.'
  Finish-Installer 0
} catch {
  Write-Host 'The effect could not be installed.' -ForegroundColor Yellow
  Write-Host $_.Exception.Message
  Write-Host 'Close Resolve before retrying, and keep the extracted package intact.'
  Finish-Installer 1
}

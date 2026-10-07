param([string]$Profiles)
$ErrorActionPreference = 'Stop'
$companionRoot = $PSScriptRoot
$sourceExe = Join-Path $companionRoot 'Windows\bin\Release\net9.0-windows\SpektrafilmMidi.exe'
$publishedExe = Join-Path $companionRoot 'SpektrafilmMidi.exe'
$selectedExe = if (Test-Path -LiteralPath $publishedExe) { $publishedExe } else { $sourceExe }
if (-not (Test-Path -LiteralPath $selectedExe)) { throw 'Companion is not built. Run the project Build.ps1 first.' }
if (-not $Profiles) { $Profiles = Join-Path (Split-Path -Parent $companionRoot) 'profiles' }
$profilePath = (Resolve-Path -LiteralPath $Profiles).Path
Start-Process -FilePath $selectedExe -ArgumentList @('--profiles', ('"' + $profilePath + '"'))

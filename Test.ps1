[CmdletBinding()]
param([string]$Python=(Join-Path $PSScriptRoot '.build/python/Scripts/python.exe'), [switch]$SkipGpu)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $PSScriptRoot
$validationRoot=Join-Path $PSScriptRoot '.build/validation'
New-Item -ItemType Directory -Path $validationRoot -Force | Out-Null
function Test-Native([string]$name,[string]$exe,[string[]]$arguments) {
  & $exe @arguments 2>&1 | Tee-Object -FilePath (Join-Path $validationRoot "$name.txt")
  if ($LASTEXITCODE -ne 0) { throw "$name failed with exit code $LASTEXITCODE" }
}
Test-Native 'host-contract' (Join-Path $PSScriptRoot '.build/host-tests/Release/HostHarness.exe') @((Join-Path $PSScriptRoot '.build/plugin/spektrafilm_midi.ofx.bundle/Contents/Win64/spektrafilm_midi.ofx'),(Join-Path $PSScriptRoot '.build/plugin/spektrafilm.ofx.bundle/Contents/Win64/spektrafilm.ofx'))
$brokerTest=Join-Path $PSScriptRoot '.build/plugin/Release/spektrafilm_midi_broker_tests.exe'
if (Test-Path -LiteralPath $brokerTest) { Test-Native 'broker' $brokerTest @() }
Test-Native 'companion' 'dotnet' @('run','--project',(Join-Path $PSScriptRoot 'companion.tests/Spektrafilm.Control.Tests.csproj'),'--configuration','Release','--no-build')
Test-Native 'profiles' $Python @('-m','unittest','discover','-s',(Join-Path $PSScriptRoot 'profiles/tests'),'-v')
Test-Native 'end-to-end' $Python @((Join-Path $PSScriptRoot 'tests/end_to_end.py'))
& (Join-Path $PSScriptRoot 'tests/Installer.Tests.ps1') 2>&1 | Tee-Object -FilePath (Join-Path $validationRoot 'installer.txt')
if (-not $SkipGpu) {
  Test-Native 'vulkan-core' (Join-Path $PSScriptRoot '.build/plugin/Release/SpektraVulkanCopyHarness.exe') @('--core-pass','--tile-mode','legacy')
  Test-Native 'vulkan-print-scan' (Join-Path $PSScriptRoot '.build/plugin/Release/SpektraVulkanCopyHarness.exe') @('--print-scan-pass','--tile-mode','legacy')
}
Write-Output "Automated checks passed. Logs: $validationRoot. Real Resolve/panel acceptance is separate; these tests do not prove it."

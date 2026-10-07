[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$DestinationRoot = (Join-Path $env:CommonProgramFiles 'OFX/Plugins'),
  [switch]$Apply
)
$ErrorActionPreference='Stop'
$bundleName='spektrafilm_midi.ofx.bundle'
$expectedId='local.tangentmidi.spektrafilm'
$sourceBundle=Join-Path $PSScriptRoot $bundleName
$sourceManifest=Join-Path $sourceBundle 'Contents/Resources/plugin_manifest.json'
if (-not (Test-Path -LiteralPath $sourceManifest)) { throw 'Run this script from the packaged distribution containing the MIDI bundle.' }
$sourceIdentity=Get-Content -LiteralPath $sourceManifest -Raw | ConvertFrom-Json
if ($sourceIdentity.id -ne $expectedId) { throw 'Source is not the expected separately identified MIDI variant.' }
$resolvedRoot=[IO.Path]::GetFullPath($DestinationRoot)
$destination=[IO.Path]::GetFullPath((Join-Path $resolvedRoot $bundleName))
if ([IO.Path]::GetFileName($destination) -ne $bundleName -or [IO.Path]::GetDirectoryName($destination) -ne $resolvedRoot.TrimEnd('\','/')) { throw 'Unsafe destination path.' }
foreach ($candidate in @($sourceBundle,$resolvedRoot,$destination,(Join-Path $destination 'Contents'))) {
  if ((Test-Path -LiteralPath $candidate) -and ((Get-Item -LiteralPath $candidate -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Refusing installation through a linked bundle/directory.' }
}
if (Test-Path -LiteralPath $destination) {
  $existingManifest=Join-Path $destination 'Contents/Resources/plugin_manifest.json'
  if (-not (Test-Path -LiteralPath $existingManifest)) { throw 'Refusing to overwrite an unrecognized existing bundle.' }
  $existingIdentity=Get-Content -LiteralPath $existingManifest -Raw | ConvertFrom-Json
  if ($existingIdentity.id -ne $expectedId) { throw 'Refusing to overwrite a different plugin identity.' }
}
Write-Output "Install only: $destination"
Write-Output 'Regular Spektrafilm bundles, user presets, and Tangent configuration are not installation targets.'
if (-not $Apply) { Write-Output 'Preview only. Close Resolve, then run with -Apply to install. The system OFX directory normally requires an administrator terminal.'; return }
if (Get-Process Resolve -ErrorAction SilentlyContinue) { throw 'Close Resolve before installing an OFX binary.' }
if ($PSCmdlet.ShouldProcess($destination,'Install the separate MIDI bundle')) {
  if (-not (Test-Path -LiteralPath $resolvedRoot)) { New-Item -ItemType Directory -Path $resolvedRoot -Force | Out-Null }
  if (-not (Test-Path -LiteralPath $destination)) { New-Item -ItemType Directory -Path $destination | Out-Null }
  Copy-Item -LiteralPath (Join-Path $sourceBundle 'Contents') -Destination $destination -Recurse -Force
  Write-Output 'Installed the separate MIDI variant. Restart Resolve and search for Spektrafilm MIDI.'
}

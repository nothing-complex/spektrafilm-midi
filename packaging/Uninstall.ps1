[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [string]$DestinationRoot = (Join-Path $env:CommonProgramFiles 'OFX/Plugins'),
  [switch]$Apply
)
$ErrorActionPreference='Stop'
$bundleName='spektrafilm_midi.ofx.bundle'
$resolvedRoot=[IO.Path]::GetFullPath($DestinationRoot).TrimEnd('\','/')
$destination=[IO.Path]::GetFullPath((Join-Path $resolvedRoot $bundleName))
if ([IO.Path]::GetFileName($destination) -ne $bundleName -or [IO.Path]::GetDirectoryName($destination) -ne $resolvedRoot) { throw 'Unsafe uninstall target.' }
if (-not (Test-Path -LiteralPath $destination)) { Write-Output 'The MIDI bundle is not installed at this location.'; return }
foreach ($candidate in @($resolvedRoot,$destination)) {
  if ((Get-Item -LiteralPath $candidate -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing removal through a linked bundle/directory.' }
}
$manifest=Join-Path $destination 'Contents/Resources/plugin_manifest.json'
if (-not (Test-Path -LiteralPath $manifest)) { throw 'Refusing to remove an unrecognized bundle.' }
$identity=Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
if ($identity.id -ne 'local.tangentmidi.spektrafilm') { throw 'Refusing to remove a different plugin identity.' }
Write-Output "Remove only: $destination"
if (-not $Apply) { Write-Output 'Preview only. Close Resolve, then run with -Apply. User settings and presets are preserved.'; return }
if (Get-Process Resolve -ErrorAction SilentlyContinue) { throw 'Close Resolve before removing an OFX binary.' }
if ($PSCmdlet.ShouldProcess($destination,'Remove only the identified MIDI bundle')) {
  Remove-Item -LiteralPath $destination -Recurse -Force
  Write-Output 'Removed the MIDI bundle. Regular Spektrafilm and user settings are preserved.'
}

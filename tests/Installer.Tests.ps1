[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testRoot=[IO.Path]::GetFullPath((Join-Path $projectRoot '.build/installer-contract'))
if ([IO.Path]::GetDirectoryName($testRoot) -ne (Join-Path $projectRoot '.build')) { throw 'Unsafe test directory.' }
if (Test-Path -LiteralPath $testRoot) {
  if ((Get-Item -LiteralPath $testRoot -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Test directory is linked.' }
  Remove-Item -LiteralPath $testRoot -Recurse -Force
}
$sourceRoot=Join-Path $testRoot 'package'
$destinationRoot=Join-Path $testRoot 'OFX/Plugins'
$bundle='spektrafilm_midi.ofx.bundle'
$sourceBundle=Join-Path $sourceRoot $bundle
$sourceResources=Join-Path $sourceBundle 'Contents/Resources'
$regular=Join-Path $destinationRoot 'spektrafilm.ofx.bundle/Contents/Win64/spektrafilm.ofx'
New-Item -ItemType Directory -Path $sourceResources,(Join-Path $sourceBundle 'Contents/Win64'),([IO.Path]::GetDirectoryName($regular)) -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'packaging/Install.ps1'),(Join-Path $projectRoot 'packaging/Uninstall.ps1') -Destination $sourceRoot
'regular plugin must survive byte for byte' | Set-Content -LiteralPath $regular -Encoding ascii
$regularHash=(Get-FileHash -LiteralPath $regular).Hash
'{"id":"local.tangentmidi.spektrafilm"}' | Set-Content -LiteralPath (Join-Path $sourceResources 'plugin_manifest.json') -Encoding utf8
'test MIDI binary' | Set-Content -LiteralPath (Join-Path $sourceBundle 'Contents/Win64/spektrafilm_midi.ofx') -Encoding ascii
function Assert([bool]$condition,[string]$message) { if (-not $condition) { throw $message }; Write-Output "PASS $message" }
$install=Join-Path $sourceRoot 'Install.ps1'
$uninstall=Join-Path $sourceRoot 'Uninstall.ps1'
$installedBundle=Join-Path $destinationRoot $bundle
& $install -DestinationRoot $destinationRoot
Assert (-not (Test-Path -LiteralPath $installedBundle)) 'installer preview writes nothing'
& $install -DestinationRoot $destinationRoot -Apply -Confirm:$false
Assert (Test-Path -LiteralPath (Join-Path $installedBundle 'Contents/Win64/spektrafilm_midi.ofx')) 'installer targets the separate MIDI bundle'
& $install -DestinationRoot $destinationRoot -Apply -Confirm:$false
Assert (-not (Test-Path -LiteralPath (Join-Path $installedBundle 'Contents/Contents'))) 'repeat installation does not nest Contents'
Assert ((Get-FileHash -LiteralPath $regular).Hash -eq $regularHash) 'regular binary unchanged after installation and update'
& $uninstall -DestinationRoot $destinationRoot
Assert (Test-Path -LiteralPath $installedBundle) 'uninstaller preview preserves the MIDI bundle'
$installedManifest=Join-Path $installedBundle 'Contents/Resources/plugin_manifest.json'
'{"id":"org.spektrafilm.regular"}' | Set-Content -LiteralPath $installedManifest -Encoding utf8
$refusedInstall=$false
try { & $install -DestinationRoot $destinationRoot -Apply -Confirm:$false } catch { $refusedInstall=$true }
Assert $refusedInstall 'installer refuses a different existing plugin identity'
$refusedUninstall=$false
try { & $uninstall -DestinationRoot $destinationRoot -Apply -Confirm:$false } catch { $refusedUninstall=$true }
Assert $refusedUninstall 'uninstaller refuses a different plugin identity'
'{"id":"local.tangentmidi.spektrafilm"}' | Set-Content -LiteralPath $installedManifest -Encoding utf8
& $uninstall -DestinationRoot $destinationRoot -Apply -Confirm:$false
Assert (-not (Test-Path -LiteralPath $installedBundle)) 'uninstaller removes only the MIDI sibling'
Assert ((Get-FileHash -LiteralPath $regular).Hash -eq $regularHash) 'regular binary unchanged after sibling removal'
Write-Output 'Installer contract passed entirely within the workspace; no system OFX directory was changed.'

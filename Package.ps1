[CmdletBinding()]
param([string]$Version='0.1.1-prototype', [switch]$Zip, [switch]$Source = $true)
$ErrorActionPreference='Stop'
$projectRoot=$PSScriptRoot
if ($Version -notmatch '^[0-9A-Za-z._-]+$') { throw 'Invalid version string.' }
$packageRoot=Join-Path $projectRoot "dist/Spektrafilm-MIDI-$Version"
$distRoot=[IO.Path]::GetFullPath((Join-Path $projectRoot 'dist'))
$bundleRoot=Join-Path $projectRoot '.build/plugin/spektrafilm_midi.ofx.bundle'
if (-not (Test-Path -LiteralPath (Join-Path $bundleRoot 'Contents/Win64/spektrafilm_midi.ofx'))) { throw 'Build the MIDI OFX target first.' }
function Reset-PackageDirectory([string]$path) {
  $absolute=[IO.Path]::GetFullPath($path)
  if ([IO.Path]::GetDirectoryName($absolute) -ne $distRoot -or [IO.Path]::GetFileName($absolute) -notlike 'Spektrafilm-MIDI-*') { throw 'Package output must be a named child of this workspace dist directory.' }
  foreach ($candidate in @($distRoot,$absolute)) {
    if (Test-Path -LiteralPath $candidate) {
      if ((Get-Item -LiteralPath $candidate -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing to replace a linked package directory.' }
    }
  }
  if (Test-Path -LiteralPath $absolute) { Remove-Item -LiteralPath $absolute -Recurse -Force }
  New-Item -ItemType Directory -Path $absolute -Force | Out-Null
}
Reset-PackageDirectory $packageRoot
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
$env:DOTNET_CLI_HOME=Join-Path $projectRoot '.build/dotnet-home'
$env:DOTNET_CLI_TELEMETRY_OPTOUT='1'
$env:DOTNET_GENERATE_ASPNET_CERTIFICATE='false'
& dotnet publish (Join-Path $projectRoot 'companion/Windows/SpektrafilmMidi.csproj') -c Release --no-restore --self-contained false -o (Join-Path $packageRoot 'companion')
if ($LASTEXITCODE -ne 0) { throw 'Companion publication failed.' }
Copy-Item -LiteralPath $bundleRoot -Destination $packageRoot -Recurse -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'profiles') -Destination $packageRoot -Recurse -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs') -Destination $packageRoot -Recurse -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'packaging/Install.ps1'),(Join-Path $projectRoot 'packaging/Uninstall.ps1') -Destination $packageRoot -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md') -Destination $packageRoot -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'THIRD_PARTY_NOTICES.md'),(Join-Path $projectRoot 'MODIFICATIONS.md') -Destination $packageRoot -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'companion/README.md') -Destination (Join-Path $packageRoot 'docs/COMPANION.md') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'companion/README.md') -Destination (Join-Path $packageRoot 'companion/README.md') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'plugin/LICENSE.txt') -Destination (Join-Path $packageRoot 'LICENSE-GPL-3.0.txt') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE.txt') -Destination $packageRoot -Force
Get-ChildItem -LiteralPath (Join-Path $packageRoot 'profiles') -Recurse -Directory -Filter '__pycache__' | ForEach-Object {
  if ($_.FullName.StartsWith((Join-Path $packageRoot 'profiles') + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
}
@'
@echo off
cd /d "%~dp0"
start "" "%~dp0companion\SpektrafilmMidi.exe" --profiles "%~dp0profiles"
'@ | Set-Content -LiteralPath (Join-Path $packageRoot 'Launch Companion.cmd') -Encoding ascii
$manifest=[ordered]@{
  version=$Version; status='prototype'; platform='Windows x64'; requires='.NET 9 Desktop Runtime and Vulkan-capable GPU';
  pluginId='local.tangentmidi.spektrafilm'; upstreamCommit='86476afc5b077de77e2278e3658d1ba9309892a1';
  openfxCommit='e40728885390ec16276d11e00025de9b4282060c';
  automaticDispatch='Optional UIAutomation binding, only if Resolve exposes the Apply MIDI button and exact armed target marker; manual host Apply otherwise.';
  limitations=@('Public source baseline predates installed current Spektrafilm.','Academy printer-density data absent; filtered-enlarger fallback.','Automatic host dispatch and physical panels require actual Resolve acceptance testing.','Transport command adapter and whole-gesture undo are not implemented.');
  files=@(Get-ChildItem -LiteralPath $packageRoot -Recurse -File | ForEach-Object { [ordered]@{path=[IO.Path]::GetRelativePath($packageRoot,$_.FullName);sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash} })
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $packageRoot 'build-manifest.json') -Encoding utf8
if ($Zip) { Compress-Archive -LiteralPath $packageRoot -DestinationPath "$packageRoot.zip" -Force }
if ($Source) {
  $sourceRoot=Join-Path $distRoot "Spektrafilm-MIDI-$Version-source"
  Reset-PackageDirectory $sourceRoot
  $rootFiles=@('README.md','Build.ps1','Test.ps1','Package.ps1','build-requirements.txt','.gitignore','THIRD_PARTY_NOTICES.md','MODIFICATIONS.md','LICENSE.txt')
  foreach ($name in $rootFiles) { Copy-Item -LiteralPath (Join-Path $projectRoot $name) -Destination $sourceRoot -Force }
  foreach ($folder in @('companion','companion.tests','profiles','tests','docs','packaging')) {
    Get-ChildItem -LiteralPath (Join-Path $projectRoot $folder) -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/](bin|obj|__pycache__)[\\/]' } | ForEach-Object {
      $target=Join-Path $sourceRoot ([IO.Path]::GetRelativePath($projectRoot,$_.FullName))
      New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($target)) -Force | Out-Null
      Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }
  }
  if (Test-Path -LiteralPath (Join-Path $projectRoot 'plugin/.git')) {
    $pluginSource=Join-Path $projectRoot 'plugin'
    # The app sandbox and packaging shell can have different Windows owners.
    # Trust this known workspace checkout only for this invocation, never globally.
    $gitSafeDirectory=$pluginSource.Replace('\','/')
    $pluginFiles=& git -c "safe.directory=$gitSafeDirectory" -C $pluginSource ls-files --cached --others --exclude-standard
    if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate the working plugin source.' }
  } elseif (Test-Path -LiteralPath (Join-Path $projectRoot '.git')) {
    $gitSafeDirectory=$projectRoot.Replace('\','/')
    $pluginFiles=& git -c "safe.directory=$gitSafeDirectory" -C $projectRoot ls-files --cached --others --exclude-standard -- plugin
    if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate the project plugin source.' }
    $pluginFiles=$pluginFiles | ForEach-Object { $_.Substring('plugin/'.Length) }
  } else {
    $pluginFiles=Get-ChildItem -LiteralPath (Join-Path $projectRoot 'plugin') -Recurse -File -Force |
      Where-Object { $_.FullName -notmatch '[\\/](bin|obj|build|\.build|\.git|__pycache__)[\\/]' -and $_.Extension -notin @('.pyc','.log','.ofx','.exe','.dll','.pdb') } |
      ForEach-Object { [IO.Path]::GetRelativePath((Join-Path $projectRoot 'plugin'),$_.FullName) }
  }
  foreach ($name in $pluginFiles) {
    $sourceFile=Join-Path (Join-Path $projectRoot 'plugin') $name
    if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) { continue }
    $target=Join-Path (Join-Path $sourceRoot 'plugin') $name
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($target)) -Force | Out-Null
    Copy-Item -LiteralPath $sourceFile -Destination $target -Force
  }
  Copy-Item -LiteralPath (Join-Path $packageRoot 'build-manifest.json') -Destination $sourceRoot -Force
  if ($Zip) { Compress-Archive -LiteralPath $sourceRoot -DestinationPath "$sourceRoot.zip" -Force }
  Write-Output "Source: $sourceRoot"
}
Write-Output "Packaged $packageRoot"

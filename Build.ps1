[CmdletBinding()]
param(
  [string]$Python = '',
  [ValidateSet('Release')][string]$Configuration = 'Release',
  [switch]$Bootstrap
)
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
function Run-Native([string]$exe, [string[]]$arguments) {
  & $exe @arguments
  if ($LASTEXITCODE -ne 0) { throw "$exe failed with exit code $LASTEXITCODE" }
}
$buildRoot = Join-Path $projectRoot '.build'
$sdkRoot = Join-Path $projectRoot 'dependencies/openfx'
$pinnedSdk = 'e40728885390ec16276d11e00025de9b4282060c'
if (-not $Python) { $Python = Join-Path $buildRoot 'python/Scripts/python.exe' }
if ($Bootstrap) {
  if (-not (Test-Path -LiteralPath $sdkRoot)) {
    Run-Native 'git' @('clone','https://github.com/AcademySoftwareFoundation/openfx.git',$sdkRoot)
    Run-Native 'git' @('-C',$sdkRoot,'checkout',$pinnedSdk)
  }
  if (-not (Test-Path -LiteralPath $Python)) {
    Run-Native 'python' @('-m','venv',(Join-Path $buildRoot 'python'))
  }
  Run-Native $Python @('-m','pip','install','-r',(Join-Path $projectRoot 'build-requirements.txt'))
}
if (-not (Test-Path -LiteralPath $Python)) { throw 'Build Python is missing. Supply -Python or run -Bootstrap with Python on PATH.' }
if (-not (Test-Path -LiteralPath (Join-Path $sdkRoot 'include/ofxImageEffect.h'))) { throw 'OpenFX SDK is missing. Run Build.ps1 -Bootstrap.' }
$sdkCommit=& git -C $sdkRoot rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $sdkCommit.Trim() -ne $pinnedSdk) { throw "The OpenFX dependency must match pinned commit $pinnedSdk. Resolve a different existing dependency checkout explicitly before building." }
if (-not $env:VULKAN_SDK) { throw 'Install/set VULKAN_SDK before building (Vulkan headers, library and GLSL compiler required).' }
$nativeBuild = Join-Path $buildRoot 'plugin'
Run-Native 'cmake' @('-S',(Join-Path $projectRoot 'plugin'),'-B',$nativeBuild,'-G','Visual Studio 17 2022','-A','x64',"-DPython3_EXECUTABLE=$Python","-DSPEKTRAFILM_OFX_ROOT=$sdkRoot",'-DSPEKTRAFILM_RELEASE_LTO=OFF')
$targets = @('spektrafilm_midi','spektrafilm_midi_broker_tests','SpektraVulkanCopyHarness','spektrafilm')
Run-Native 'cmake' (@('--build',$nativeBuild,'--config',$Configuration,'--target') + $targets + @('--parallel','4'))
Run-Native 'cmake' @('-S',(Join-Path $projectRoot 'tests/native'),'-B',(Join-Path $buildRoot 'host-tests'),'-G','Visual Studio 17 2022','-A','x64')
Run-Native 'cmake' @('--build',(Join-Path $buildRoot 'host-tests'),'--config',$Configuration,'--parallel','2')
$env:DOTNET_CLI_HOME=Join-Path $buildRoot 'dotnet-home'
$env:DOTNET_CLI_TELEMETRY_OPTOUT='1'
$env:DOTNET_GENERATE_ASPNET_CERTIFICATE='false'
Run-Native 'dotnet' @('restore',(Join-Path $projectRoot 'companion/Windows/SpektrafilmMidi.csproj'),'--configfile',(Join-Path $projectRoot 'companion/NuGet.Config'))
Run-Native 'dotnet' @('build',(Join-Path $projectRoot 'companion/Windows/SpektrafilmMidi.csproj'),'--configuration',$Configuration,'--no-restore')
Run-Native 'dotnet' @('restore',(Join-Path $projectRoot 'companion.tests/Spektrafilm.Control.Tests.csproj'),'--configfile',(Join-Path $projectRoot 'companion/NuGet.Config'))
Run-Native 'dotnet' @('build',(Join-Path $projectRoot 'companion.tests/Spektrafilm.Control.Tests.csproj'),'--configuration',$Configuration,'--no-restore')
Write-Output 'Build completed. Run Test.ps1, then Package.ps1.'

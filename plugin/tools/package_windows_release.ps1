param(
  [string]$BuildDir = "",
  [string]$OutputDir = "",
  [string]$Configuration = "Release",
  [string]$Generator = "",
  [string]$Platform = "x64"
)

$ErrorActionPreference = "Stop"

function Write-ReleaseLog {
  param([string]$Message)
  Write-Host "[Windows release] $Message"
}

function Convert-ToFullPath {
  param([string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
}

function Resolve-RequiredCommand {
  param([string]$Name)

  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $command) {
    throw "$Name is required and was not found on PATH."
  }
  return $command.Source
}

function Invoke-LoggedNativeCommand {
  param(
    [string]$Description,
    [string]$FilePath,
    [string[]]$ArgumentList
  )

  Write-Output "> $FilePath $($ArgumentList -join ' ')"

  $oldErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    & $FilePath @ArgumentList 2>&1 | ForEach-Object { "$_" }
    $exitCode = $LASTEXITCODE
  }
  finally {
    $ErrorActionPreference = $oldErrorActionPreference
  }

  if ($exitCode -ne 0) {
    throw "$Description failed with exit code $exitCode."
  }
}

function Remove-PathIfExists {
  param([string]$Path)
  if (Test-Path $Path) {
    Remove-Item -LiteralPath $Path -Recurse -Force
  }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

if (-not $BuildDir) {
  $BuildDir = Join-Path $ProjectRoot "build-windows"
}
if (-not $OutputDir) {
  $OutputDir = Join-Path $ProjectRoot "..\..\website\public\downloads"
}

$BuildDir = Convert-ToFullPath $BuildDir
$OutputDir = Convert-ToFullPath $OutputDir

$ResolvedCMake = Resolve-RequiredCommand "cmake"

$DefaultManual = Join-Path $ProjectRoot "..\..\docs\user_manual\main.pdf"
if (Test-Path $DefaultManual) {
  $Manual = Convert-ToFullPath $DefaultManual
}
else {
  $Manual = Join-Path $ProjectRoot "documentation\spektrafilm_reference_guide.pdf"
}
if (-not (Test-Path $Manual)) {
  throw "Manual PDF was not found."
}

New-Item -ItemType Directory -Force -Path $BuildDir, $OutputDir | Out-Null

$configureArgs = @("-S", $ProjectRoot, "-B", $BuildDir)
if ($Generator) {
  $configureArgs += @("-G", $Generator)
  if ($Platform -and $Generator -match "Visual Studio") {
    $configureArgs += @("-A", $Platform)
  }
}

Write-ReleaseLog "configuring $Configuration Windows release build in $BuildDir"
Invoke-LoggedNativeCommand "CMake configure" $ResolvedCMake $configureArgs

Write-ReleaseLog "building public OFX bundles"
Invoke-LoggedNativeCommand `
  "CMake public bundle build" `
  $ResolvedCMake `
  @("--build", $BuildDir, "--config", $Configuration, "--target", "spektrafilmBundleResources", "spektrafilm_flowBundleResources", "--parallel")

$ReleaseDir = Join-Path $BuildDir "windows-release"
$ZipStage = Join-Path $ReleaseDir "zip-stage"
$ZipPath = Join-Path $OutputDir "spektrafilm-OFX-Windows.zip"
$LegacyFlowZipPath = Join-Path $OutputDir "spektrafilm_flow-OFX-Windows.zip"

Write-ReleaseLog "verifying built bundle layout"
$Artifacts = @("spektrafilm_flow", "spektrafilm")
foreach ($artifact in $Artifacts) {
  $bundle = Join-Path $BuildDir "$artifact.ofx.bundle"
  $executable = Join-Path $bundle "Contents\Win64\$artifact.ofx"
  if (-not (Test-Path $bundle)) {
    throw "Missing built bundle: $bundle"
  }
  if (-not (Test-Path $executable)) {
    throw "Missing OFX executable: $executable"
  }
}

Write-ReleaseLog "assembling public ZIP stage"
Remove-PathIfExists $ReleaseDir
New-Item -ItemType Directory -Force -Path $ZipStage, (Join-Path $ZipStage "Legal") | Out-Null

foreach ($artifact in $Artifacts) {
  Copy-Item `
    -LiteralPath (Join-Path $BuildDir "$artifact.ofx.bundle") `
    -Destination (Join-Path $ZipStage "$artifact.ofx.bundle") `
    -Recurse `
    -Force
}

if (Test-Path (Join-Path $ZipStage "spektrafilm_dev.ofx.bundle")) {
  throw "dev bundle must not be included in the public release ZIP."
}

Copy-Item -LiteralPath (Join-Path $ProjectRoot "tools\windows_install\install.bat") -Destination (Join-Path $ZipStage "install.bat") -Force
Copy-Item -LiteralPath (Join-Path $ProjectRoot "install_instructions.txt") -Destination (Join-Path $ZipStage "install_instructions.txt") -Force
Copy-Item -LiteralPath $Manual -Destination (Join-Path $ZipStage "manual.pdf") -Force
Copy-Item -LiteralPath (Join-Path $ProjectRoot "Legal\SPEKTRAFILM_OFX_LICENSE.txt") -Destination (Join-Path $ZipStage "Legal\SPEKTRAFILM_OFX_LICENSE.txt") -Force
Copy-Item -LiteralPath (Join-Path $ProjectRoot "Legal\SPEKTRAFILM_OFX_LUT_LICENSE.txt") -Destination (Join-Path $ZipStage "Legal\SPEKTRAFILM_OFX_LUT_LICENSE.txt") -Force
Copy-Item -LiteralPath (Join-Path $ProjectRoot "Legal\THIRD_PARTY_NOTICES.txt") -Destination (Join-Path $ZipStage "Legal\THIRD_PARTY_NOTICES.txt") -Force

Write-ReleaseLog "writing public ZIP"
Remove-PathIfExists $ZipPath
Remove-PathIfExists $LegacyFlowZipPath
Compress-Archive -Path (Join-Path $ZipStage "*") -DestinationPath $ZipPath -CompressionLevel Optimal

Write-ReleaseLog "wrote $ZipPath"

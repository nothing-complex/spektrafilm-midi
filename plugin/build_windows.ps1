param(
  [string]$BuildDir = "$PSScriptRoot\build-windows",
  [string]$Configuration = "Release",
  [string]$Generator = "",
  [string]$Platform = "x64",
  [switch]$RunCopyHarness,
  [switch]$RunCoreHarness,
  [switch]$RunPrintScanHarness,
  [switch]$RunStandardHarness,
  [switch]$RunHalationHarness,
  [switch]$RunDiffusionHarness,
  [switch]$RunDirHarness,
  [switch]$RunScannerPostHarness,
  [switch]$RunPreviewGrainHarness,
  [switch]$RunProductionGrainHarness,
  [switch]$Install
)

$ErrorActionPreference = "Stop"

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

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
  throw "cmake is required. Install CMake and make sure it is on PATH."
}

if (-not $env:VULKAN_SDK) {
  Write-Warning "VULKAN_SDK is not set. CMake can still configure if Vulkan and glslc/glslangValidator are on PATH."
}
else {
  $vulkanBin = Join-Path $env:VULKAN_SDK "Bin"
  if (Test-Path $vulkanBin) {
    $env:Path = "$vulkanBin;$env:Path"
  }
}

if (-not (Get-Command glslc -ErrorAction SilentlyContinue) -and
    -not (Get-Command glslangValidator -ErrorAction SilentlyContinue)) {
  Write-Warning "glslc or glslangValidator was not found on PATH. Install the Vulkan SDK before configuring."
}

$configureArgs = @("-S", $PSScriptRoot, "-B", $BuildDir)
if ($Generator) {
  $configureArgs += @("-G", $Generator)
  if ($Platform -and $Generator -match "Visual Studio") {
    $configureArgs += @("-A", $Platform)
  }
}

Invoke-LoggedNativeCommand "CMake configure" "cmake" $configureArgs
Invoke-LoggedNativeCommand "CMake build" "cmake" @("--build", $BuildDir, "--config", $Configuration, "--parallel")

if ($RunCopyHarness) {
  $harnessCandidates = @(
    (Join-Path $BuildDir "$Configuration\SpektraVulkanCopyHarness.exe"),
    (Join-Path $BuildDir "SpektraVulkanCopyHarness.exe")
  )
  $harness = $harnessCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $harness) {
    throw "SpektraVulkanCopyHarness.exe was not found in $BuildDir."
  }
  & $harness
  if ($LASTEXITCODE -ne 0) {
    throw "SpektraVulkanCopyHarness.exe failed with exit code $LASTEXITCODE."
  }
}

if ($RunCoreHarness) {
  $harnessCandidates = @(
    (Join-Path $BuildDir "$Configuration\SpektraVulkanCopyHarness.exe"),
    (Join-Path $BuildDir "SpektraVulkanCopyHarness.exe")
  )
  $harness = $harnessCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $harness) {
    throw "SpektraVulkanCopyHarness.exe was not found in $BuildDir."
  }
  & $harness --core-pass
  if ($LASTEXITCODE -ne 0) {
    throw "SpektraVulkanCopyHarness.exe --core-pass failed with exit code $LASTEXITCODE."
  }
}

if ($RunPrintScanHarness) {
  $harnessCandidates = @(
    (Join-Path $BuildDir "$Configuration\SpektraVulkanCopyHarness.exe"),
    (Join-Path $BuildDir "SpektraVulkanCopyHarness.exe")
  )
  $harness = $harnessCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $harness) {
    throw "SpektraVulkanCopyHarness.exe was not found in $BuildDir."
  }
  & $harness --core-pass --print-scan-pass
  if ($LASTEXITCODE -ne 0) {
    throw "SpektraVulkanCopyHarness.exe --core-pass --print-scan-pass failed with exit code $LASTEXITCODE."
  }
}

if ($RunStandardHarness) {
  $harnessCandidates = @(
    (Join-Path $BuildDir "$Configuration\SpektraVulkanCopyHarness.exe"),
    (Join-Path $BuildDir "SpektraVulkanCopyHarness.exe")
  )
  $harness = $harnessCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $harness) {
    throw "SpektraVulkanCopyHarness.exe was not found in $BuildDir."
  }
  & $harness --core-pass --print-scan-pass --preview-grain-pass
  if ($LASTEXITCODE -ne 0) {
    throw "SpektraVulkanCopyHarness.exe --core-pass --print-scan-pass --preview-grain-pass failed with exit code $LASTEXITCODE."
  }
}

if ($RunHalationHarness) {
  $harnessCandidates = @(
    (Join-Path $BuildDir "$Configuration\SpektraVulkanCopyHarness.exe"),
    (Join-Path $BuildDir "SpektraVulkanCopyHarness.exe")
  )
  $harness = $harnessCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $harness) {
    throw "SpektraVulkanCopyHarness.exe was not found in $BuildDir."
  }
  & $harness --core-pass --halation-pass
  if ($LASTEXITCODE -ne 0) {
    throw "SpektraVulkanCopyHarness.exe --core-pass --halation-pass failed with exit code $LASTEXITCODE."
  }
}

if ($RunDiffusionHarness) {
  $harnessCandidates = @(
    (Join-Path $BuildDir "$Configuration\SpektraVulkanCopyHarness.exe"),
    (Join-Path $BuildDir "SpektraVulkanCopyHarness.exe")
  )
  $harness = $harnessCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $harness) {
    throw "SpektraVulkanCopyHarness.exe was not found in $BuildDir."
  }
  & $harness --core-pass --diffusion-pass
  if ($LASTEXITCODE -ne 0) {
    throw "SpektraVulkanCopyHarness.exe --core-pass --diffusion-pass failed with exit code $LASTEXITCODE."
  }
}

if ($RunDirHarness) {
  $harnessCandidates = @(
    (Join-Path $BuildDir "$Configuration\SpektraVulkanCopyHarness.exe"),
    (Join-Path $BuildDir "SpektraVulkanCopyHarness.exe")
  )
  $harness = $harnessCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $harness) {
    throw "SpektraVulkanCopyHarness.exe was not found in $BuildDir."
  }
  & $harness --core-pass --dir-pass
  if ($LASTEXITCODE -ne 0) {
    throw "SpektraVulkanCopyHarness.exe --core-pass --dir-pass failed with exit code $LASTEXITCODE."
  }
}

if ($RunScannerPostHarness) {
  $harnessCandidates = @(
    (Join-Path $BuildDir "$Configuration\SpektraVulkanCopyHarness.exe"),
    (Join-Path $BuildDir "SpektraVulkanCopyHarness.exe")
  )
  $harness = $harnessCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $harness) {
    throw "SpektraVulkanCopyHarness.exe was not found in $BuildDir."
  }
  & $harness --core-pass --print-scan-pass --scanner-post-pass
  if ($LASTEXITCODE -ne 0) {
    throw "SpektraVulkanCopyHarness.exe --core-pass --print-scan-pass --scanner-post-pass failed with exit code $LASTEXITCODE."
  }
}

if ($RunPreviewGrainHarness) {
  $harnessCandidates = @(
    (Join-Path $BuildDir "$Configuration\SpektraVulkanCopyHarness.exe"),
    (Join-Path $BuildDir "SpektraVulkanCopyHarness.exe")
  )
  $harness = $harnessCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $harness) {
    throw "SpektraVulkanCopyHarness.exe was not found in $BuildDir."
  }
  & $harness --core-pass --preview-grain-pass
  if ($LASTEXITCODE -ne 0) {
    throw "SpektraVulkanCopyHarness.exe --core-pass --preview-grain-pass failed with exit code $LASTEXITCODE."
  }
}

if ($RunProductionGrainHarness) {
  $harnessCandidates = @(
    (Join-Path $BuildDir "$Configuration\SpektraVulkanCopyHarness.exe"),
    (Join-Path $BuildDir "SpektraVulkanCopyHarness.exe")
  )
  $harness = $harnessCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $harness) {
    throw "SpektraVulkanCopyHarness.exe was not found in $BuildDir."
  }
  & $harness --core-pass --production-grain-pass
  if ($LASTEXITCODE -ne 0) {
    throw "SpektraVulkanCopyHarness.exe --core-pass --production-grain-pass failed with exit code $LASTEXITCODE."
  }
}

if ($Install) {
  Invoke-LoggedNativeCommand "CMake install" "cmake" @("--install", $BuildDir, "--config", $Configuration)
}

Write-Host "Built spektrafilm flow, spektrafilm, and spektrafilm dev Windows OFX bundles in $BuildDir"
Write-Host "Vulkan copy harness:"
Write-Host "  $BuildDir\$Configuration\SpektraVulkanCopyHarness.exe"
Write-Host "  $BuildDir\SpektraVulkanCopyHarness.exe"
Write-Host "Phase 4 core bootstrap harness:"
Write-Host "  $BuildDir\$Configuration\SpektraVulkanCopyHarness.exe --core-pass"
Write-Host "  $BuildDir\SpektraVulkanCopyHarness.exe --core-pass"
Write-Host "Phase 4 print/scan bootstrap harness:"
Write-Host "  $BuildDir\$Configuration\SpektraVulkanCopyHarness.exe --core-pass --print-scan-pass"
Write-Host "  $BuildDir\SpektraVulkanCopyHarness.exe --core-pass --print-scan-pass"
Write-Host "Resolve-standard bootstrap harness:"
Write-Host "  $BuildDir\$Configuration\SpektraVulkanCopyHarness.exe --core-pass --print-scan-pass --preview-grain-pass"
Write-Host "  $BuildDir\SpektraVulkanCopyHarness.exe --core-pass --print-scan-pass --preview-grain-pass"
Write-Host "Phase 5 halation bootstrap harness:"
Write-Host "  $BuildDir\$Configuration\SpektraVulkanCopyHarness.exe --core-pass --halation-pass"
Write-Host "  $BuildDir\SpektraVulkanCopyHarness.exe --core-pass --halation-pass"
Write-Host "Phase 5 diffusion bootstrap harness:"
Write-Host "  $BuildDir\$Configuration\SpektraVulkanCopyHarness.exe --core-pass --diffusion-pass"
Write-Host "  $BuildDir\SpektraVulkanCopyHarness.exe --core-pass --diffusion-pass"
Write-Host "Phase 5 DIR bootstrap harness:"
Write-Host "  $BuildDir\$Configuration\SpektraVulkanCopyHarness.exe --core-pass --dir-pass"
Write-Host "  $BuildDir\SpektraVulkanCopyHarness.exe --core-pass --dir-pass"
Write-Host "Phase 5 scanner post-process bootstrap harness:"
Write-Host "  $BuildDir\$Configuration\SpektraVulkanCopyHarness.exe --core-pass --print-scan-pass --scanner-post-pass"
Write-Host "  $BuildDir\SpektraVulkanCopyHarness.exe --core-pass --print-scan-pass --scanner-post-pass"
Write-Host "Phase 5 preview grain bootstrap harness:"
Write-Host "  $BuildDir\$Configuration\SpektraVulkanCopyHarness.exe --core-pass --preview-grain-pass"
Write-Host "  $BuildDir\SpektraVulkanCopyHarness.exe --core-pass --preview-grain-pass"
Write-Host "Phase 5 production grain bootstrap harness:"
Write-Host "  $BuildDir\$Configuration\SpektraVulkanCopyHarness.exe --core-pass --production-grain-pass"
Write-Host "  $BuildDir\SpektraVulkanCopyHarness.exe --core-pass --production-grain-pass"
Write-Host "Bundle layout:"
Write-Host "  $BuildDir\spektrafilm_flow.ofx.bundle\Contents\Win64\spektrafilm_flow.ofx"
Write-Host "  $BuildDir\spektrafilm.ofx.bundle\Contents\Win64\spektrafilm.ofx"
Write-Host "  $BuildDir\spektrafilm_dev.ofx.bundle\Contents\Win64\spektrafilm_dev.ofx"
if (-not $Install) {
  Write-Host "Install into Resolve's OFX folder:"
  Write-Host "  cmake --install $BuildDir --config $Configuration"
  Write-Host "or rerun this script with -Install from an elevated PowerShell."
}
Write-Host "For the public Windows ZIP with install.bat, run:"
Write-Host "  .\tools\package_windows_release.ps1 -BuildDir $BuildDir -Configuration $Configuration"

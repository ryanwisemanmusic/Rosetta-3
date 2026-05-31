#Requires -Version 5.1
<#
.SYNOPSIS
    Build WinMine for x86 and x64 with zero C Runtime dependency.

.DESCRIPTION
    Invokes MSBuild on WinMine.vcxproj for Release|x64 and Release|Win32.
    Moves resulting binaries to bin\ as MineSweeper_x64.exe / MineSweeper_x86.exe.
    After a successful build, runs post-build verification:
      - `dumpbin /imports` — asserts no msvcr*.dll / ucrtbase.dll in the import table.
    Cleans up all VS intermediate and output directories.

.PARAMETER Clean
    Switch. Runs 'Clean' before 'Build'.

.EXAMPLE
    .\build.ps1        # Build both platforms
    .\build.ps1 -Clean # Clean + rebuild both platforms
#>

[CmdletBinding()]
param(
    [switch]$Clean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Locate MSBuild via vswhere (Visual Studio 2017+)
# ---------------------------------------------------------------------------
function Find-MSBuild {
    $vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) {
        throw "vswhere.exe not found. Install Visual Studio Installer first."
    }

    $vsPath = & $vswhere -latest -prerelease -property installationPath
    if ([string]::IsNullOrEmpty($vsPath)) {
        throw "No Visual Studio installation found."
    }

    $msbuildExe = Join-Path $vsPath "MSBuild\Current\Bin\MSBuild.exe"
    if (-not (Test-Path $msbuildExe)) {
        # Fallback: try older layout
        $msbuildExe = Join-Path $vsPath "MSBuild\15.0\Bin\MSBuild.exe"
    }
    if (-not (Test-Path $msbuildExe)) {
        throw "MSBuild.exe not found under: $vsPath"
    }
    return $msbuildExe
}

# ---------------------------------------------------------------------------
# Locate dumpbin.exe via vswhere
# ---------------------------------------------------------------------------
function Find-Dumpbin {
    $vswhere  = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    $vsPath   = & $vswhere -latest -prerelease -property installationPath

    $candidates = Get-ChildItem -Recurse -Filter "dumpbin.exe" -Path (Join-Path $vsPath "VC") -ErrorAction SilentlyContinue
    if ($candidates.Count -eq 0) {
        # Try the SDK path instead
        $candidates = Get-ChildItem -Recurse -Filter "dumpbin.exe" -Path "C:\Program Files (x86)\Windows Kits" -ErrorAction SilentlyContinue
    }
    if ($candidates.Count -eq 0) {
        Write-Warning "dumpbin.exe not found — skipping import verification."
        return $null
    }
    return $candidates[0].FullName
}

# ---------------------------------------------------------------------------
# Verify binary has zero CRT imports
# ---------------------------------------------------------------------------
function Test-NoCrtImports {
    param(
        [string]$BinaryPath,
        [string]$DumpbinPath
    )

    if (-not $DumpbinPath) { return $true }

    Write-Host "  Binary : $BinaryPath"
    Write-Host "  Size   : $('{0:N0}' -f (Get-Item $BinaryPath).Length) bytes"
    Write-Host ""

    $imports = & $DumpbinPath /imports $BinaryPath 2>&1
    $crtDlls = @("msvcr", "ucrtbase", "vcruntime", "concur")
    $found   = $false

    foreach ($crt in $crtDlls) {
        $hits = $imports | Where-Object { $_ -imatch $crt }
        if ($hits) {
            Write-Error "FAIL: CRT dependency detected — $crt"
            $hits | ForEach-Object { Write-Error "      $_" }
            $found = $true
        }
    }

    if (-not $found) {
        Write-Host "  [PASS] Zero CRT imports." -ForegroundColor Green
        Write-Host ""
        Write-Host "  Import table (DLLs only):"
        $imports | Where-Object { $_ -imatch "^\s+\S+\.dll" } | ForEach-Object {
            Write-Host "    $_"
        }
        return $true
    }

    return $false
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$scriptDir  = $PSScriptRoot
$vcxproj    = Join-Path $scriptDir "WinMine.vcxproj"
$binDir     = Join-Path $scriptDir "bin"

if (-not (Test-Path $vcxproj)) {
    throw "Project file not found: $vcxproj"
}

$msbuild = Find-MSBuild
$targets = if ($Clean) { "Clean;Build" } else { "Build" }

# Platform map: MSBuild platform → output name + OutDir
# Win32 is the default platform in VS, so its OutDir is just Release\ (no platform prefix)
$platforms = [ordered]@{
    "x64"   = @{ Bin = "MineSweeper_x64.exe"; OutDir = "x64\Release" }
    "Win32" = @{ Bin = "MineSweeper_x86.exe"; OutDir = "Release"     }
}

Write-Host "=========================================="
Write-Host "  WinMine  —  No-CRT Build (All Platforms)"
Write-Host "  Targets  : $targets"
Write-Host "=========================================="
Write-Host ""

# Ensure bin\ exists
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir | Out-Null
}

# ---------------------------------------------------------------------------
# Build each platform
# ---------------------------------------------------------------------------
foreach ($platform in $platforms.Keys) {
    Write-Host "----------------------------------------"
    Write-Host "  Platform : $platform"
    Write-Host "----------------------------------------"
    Write-Host ""

    & $msbuild $vcxproj `
        /t:$targets `
        /p:Configuration=Release `
        /p:Platform=$platform `
        /v:normal

    if ($LASTEXITCODE -ne 0) {
        throw "MSBuild failed for $platform (exit code $LASTEXITCODE)"
    }

    # Move built exe to bin\
    $builtExe = Join-Path $scriptDir "$($platforms[$platform].OutDir)\WinMine.exe"
    if (-not (Test-Path $builtExe)) {
        throw "Binary not found after build: $builtExe"
    }

    $destExe = Join-Path $binDir $platforms[$platform].Bin
    Move-Item -Path $builtExe -Destination $destExe -Force

    Write-Host ""
}

# ---------------------------------------------------------------------------
# Post-build: CRT import verification on both binaries
# ---------------------------------------------------------------------------
Write-Host "=========================================="
Write-Host "  Post-Build: CRT Import Verification"
Write-Host "=========================================="
Write-Host ""

$dumpbin   = Find-Dumpbin
$allPassed = $true

foreach ($platform in $platforms.Keys) {
    $binary = Join-Path $binDir $platforms[$platform].Bin

    if (-not (Test-Path $binary)) {
        Write-Warning "Binary not found: $binary — skipping."
        continue
    }

    if (-not (Test-NoCrtImports -BinaryPath $binary -DumpbinPath $dumpbin)) {
        $allPassed = $false
    }

    Write-Host ""
}

# ---------------------------------------------------------------------------
# Cleanup: remove VS intermediate and output directories
# ---------------------------------------------------------------------------
Write-Host "=========================================="
Write-Host "  Cleanup"
Write-Host "=========================================="

$dirsToRemove = @("WinMine", "x64", "Release")

foreach ($dir in $dirsToRemove) {
    $fullDir = Join-Path $scriptDir $dir
    if (Test-Path $fullDir) {
        Remove-Item -Recurse -Force -Path $fullDir
        Write-Host "  Removed : $dir"
    }
}

Write-Host ""

# ---------------------------------------------------------------------------
# Final status
# ---------------------------------------------------------------------------
if (-not $allPassed) {
    Write-Error "Build succeeded but one or more binaries have CRT dependencies."
    exit 1
}

Write-Host "=========================================="
Write-Host "  Done. Binaries in 'bin' folder."
Write-Host "=========================================="

# cmake-system Windows/Linux helper (PC2023 copy-paste ready).
# Always drive verilator_bin.exe (withlimon PE). Never the extensionless
# Perl `verilator` (Explorer/CMD "Open with..." trap).
#
#   cd cmake-system
#   .\build_sim.ps1
#
# Conan is NOT used here (see ../cmake-conan/build_sim.ps1).
# Firmware hex still comes from the repo Makefile (needs RISC-V GCC).

#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$BuildDir = "build",
    [ValidateSet("Debug", "Release", "RelWithDebInfo", "MinSizeRel")]
    [string]$Config = "Release",
    [string]$Generator = ""
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Test-MzPe([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $false }
    $fs = [IO.File]::OpenRead($Path)
    try {
        return ($fs.ReadByte() -eq 0x4D -and $fs.ReadByte() -eq 0x5A)
    } finally { $fs.Close() }
}

function Find-VerilatorBin {
    $cands = New-Object System.Collections.Generic.List[string]
    $cands.Add("D:\verilator\bin\verilator_bin.exe")
    $cands.Add("C:\msys64\mingw64\bin\verilator_bin.exe")
    if ($env:VERILATOR_ROOT) {
        $cands.Add((Join-Path $env:VERILATOR_ROOT "bin\verilator_bin.exe"))
        $cands.Add((Join-Path $env:VERILATOR_ROOT "..\bin\verilator_bin.exe"))
        $cands.Add((Join-Path $env:VERILATOR_ROOT "..\..\bin\verilator_bin.exe"))
    }
    foreach ($c in $cands) {
        if ($c -and (Test-MzPe $c)) {
            return (Resolve-Path -LiteralPath $c).Path
        }
    }
    $cmd = Get-Command verilator_bin.exe -ErrorAction SilentlyContinue
    if ($cmd -and (Test-MzPe $cmd.Source)) { return $cmd.Source }
    return $null
}

Write-Host "cmake-system/build_sim.ps1  config=$Config  buildDir=$BuildDir"
Write-Host "withlimon: https://github.com/withlimon/verilator-windows"

$pe = Find-VerilatorBin
if ($pe) {
    Write-Host "VERILATOR_BIN (PE) = $pe"
    $binDir = Split-Path -Parent $pe
    $rootGuess = Split-Path -Parent $binDir
    if (-not $env:VERILATOR_ROOT) {
        if (Test-Path (Join-Path $rootGuess "include\verilated.h")) {
            $env:VERILATOR_ROOT = $rootGuess
        } elseif (Test-Path (Join-Path $rootGuess "share\verilator\include\verilated.h")) {
            $env:VERILATOR_ROOT = Join-Path $rootGuess "share\verilator"
        }
    }
    $env:PATH = "$binDir;$env:PATH"
    Write-Host "VERILATOR_ROOT    = $($env:VERILATOR_ROOT)"
} else {
    Write-Host "WARNING: verilator_bin.exe not on this machine yet."
    Write-Host "  Extract withlimon to D:\verilator and set VERILATOR_ROOT + PATH."
    Write-Host "  Do NOT invoke extensionless Perl ``verilator``."
}

$buildPath = if ([System.IO.Path]::IsPathRooted($BuildDir)) { $BuildDir } else { Join-Path $Here $BuildDir }

$cmakeArgs = @("-S", $Here, "-B", $buildPath)
if ($Generator) { $cmakeArgs += @("-G", $Generator) }
if ($Generator -notmatch "Visual Studio") {
    $cmakeArgs += "-DCMAKE_BUILD_TYPE=$Config"
}

Write-Host "cmake $($cmakeArgs -join ' ')"
& cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) { throw "cmake configure failed" }

$buildArgs = @("--build", $buildPath, "--config", $Config, "--target", "sim")
& cmake @buildArgs
if ($LASTEXITCODE -ne 0) { throw "cmake --build --target sim failed" }

Push-Location $buildPath
try {
    & ctest -C $Config --output-on-failure
    if ($LASTEXITCODE -ne 0) { throw "ctest failed" }
} finally {
    Pop-Location
}

Write-Host "cmake-system PASS (sim + ctest)"

# cmake-conan Windows/Linux helper (PC2023 copy-paste ready).
# Conan 2 + local recipes/verilator (withlimon PE on Windows).
# Always drive verilator_bin.exe. Never extensionless Perl `verilator`.
#
#   cd cmake-conan
#   .\build_sim.ps1
#
# PC2023: Conan 2.34 + withlimon Verilator.
# Firmware hex: committed firmware/*.hex (PICO_REBUILD_FIRMWARE=OFF default
# on Windows). Optional rebuild: MSYS2 make + RISC-V GCC
# (-DPICO_REBUILD_FIRMWARE=ON). GNU make is NOT required for Verilator cmake.

#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$BuildDir = "build",
    [ValidateSet("Debug", "Release", "RelWithDebInfo", "MinSizeRel")]
    [string]$Config = "Release",
    [string]$Generator = "",
    [string]$Profile = ""
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

function Find-GnuMake {
    $cands = New-Object System.Collections.Generic.List[string]
    $cands.Add("C:\msys64\usr\bin\make.exe")
    $cands.Add("C:\msys64\mingw64\bin\mingw32-make.exe")
    $cands.Add("C:\msys64\ucrt64\bin\mingw32-make.exe")
    $cands.Add("D:\msys64\usr\bin\make.exe")
    $cands.Add("D:\msys64\mingw64\bin\mingw32-make.exe")
    if ($env:MSYS2_ROOT) {
        $cands.Add((Join-Path $env:MSYS2_ROOT "usr\bin\make.exe"))
        $cands.Add((Join-Path $env:MSYS2_ROOT "mingw64\bin\mingw32-make.exe"))
    }
    foreach ($c in $cands) {
        if ($c -and (Test-Path -LiteralPath $c)) {
            return (Resolve-Path -LiteralPath $c).Path
        }
    }
    foreach ($name in @("make.exe", "gmake.exe", "mingw32-make.exe")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
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

Write-Host "cmake-conan/build_sim.ps1  config=$Config  buildDir=$BuildDir"
Write-Host "withlimon: https://github.com/withlimon/verilator-windows"
Write-Host "Conan 2 expected (PC2023: 2.34)"

$conan = Get-Command conan -ErrorAction SilentlyContinue
if (-not $conan) {
    throw "conan not on PATH. Install Conan 2 (PC2023: 2.34) or use cmake-system/ instead."
}
Write-Host "conan = $($conan.Source)"

& conan export (Join-Path $Here "recipes\verilator")
if ($LASTEXITCODE -ne 0) { throw "conan export recipes/verilator failed" }

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
    Write-Host "verilator_bin.exe not preinstalled; recipe will fetch/package withlimon on Windows."
}

$make = Find-GnuMake
if ($make) {
    Write-Host "GNU make (optional firmware rebuild) = $make"
    $env:PATH = "$(Split-Path -Parent $make);$env:PATH"
} else {
    Write-Host "GNU make not on PATH; Verilator cmake path does not need it."
    Write-Host "  Firmware: using committed firmware/*.hex (PICO_REBUILD_FIRMWARE=OFF)."
}

$repoRoot = Split-Path -Parent $Here
foreach ($hexName in @("hello.hex", "firmware.hex")) {
    $hexPath = Join-Path $repoRoot "firmware\$hexName"
    if (-not (Test-Path -LiteralPath $hexPath)) {
        Write-Host "WARNING: missing $hexPath (copy from a Linux build for ctest)."
    }
}

$buildPath = if ([System.IO.Path]::IsPathRooted($BuildDir)) { $BuildDir } else { Join-Path $Here $BuildDir }

$cmakeArgs = @(
    "-S", $Here,
    "-B", $buildPath,
    "-DCMAKE_PROJECT_TOP_LEVEL_INCLUDES=$Here\conan_provider.cmake",
    "-DCONAN_INSTALL_ARGS=--build=missing;--no-remote"
)
if ($Generator) { $cmakeArgs += @("-G", $Generator) }
if ($Generator -notmatch "Visual Studio") {
    $cmakeArgs += "-DCMAKE_BUILD_TYPE=$Config"
}
if ($Profile) {
    $cmakeArgs += "-DCONAN_HOST_PROFILE=$Profile"
    $cmakeArgs += "-DCONAN_BUILD_PROFILE=$Profile"
}
if ($make) {
    $cmakeArgs += "-DPICO_GNU_MAKE=$($make -replace '\\','/')"
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

Write-Host "cmake-conan PASS (sim + ctest)"

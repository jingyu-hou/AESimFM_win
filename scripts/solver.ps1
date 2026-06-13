<#
.SYNOPSIS
    AESimFM v2.0 solver wrapper. Drop this in a PATH directory to run `solver disk`.
.DESCRIPTION
    Locates solver.exe from the packaged directory or the build directory, sets up
    the required MSYS2 UCRT64 runtime DLL path automatically, and runs the solver.

    Usage from PowerShell:
        solver disk          # runs solver.exe -i disk from the current directory
        solver -i disk       # legacy form
        solver --help        # shows help
        solver --version     # shows version
        solver --threads 8 disk  # runs with 8 threads

    Installation:
        Copy this script to C:\Users\<user>\.local\bin\solver.ps1
        Ensure C:\Users\<user>\.local\bin is in your PATH.
#>

param(
    [Parameter(Position=0)]
    [string]$JobName,

    [Parameter()]
    [string]$i,

    [Parameter()]
    [int]$Threads,

    [Parameter()]
    [switch]$Help,

    [Parameter()]
    [switch]$Version
)

$ErrorActionPreference = "Stop"

# Locate solver root: try packaged dir first, then build dir
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$candidates = @(
    (Split-Path -Parent $scriptDir),
    (Join-Path $scriptDir "..\.."),
    "D:\AESimFM_win"
)

$solverRoot = $null
foreach ($c in $candidates) {
    $pkgExe = Join-Path $c "package\bin\solver.exe"
    $bldExe = Join-Path $c "build\src\solver\solver.exe"
    if (Test-Path $pkgExe) { $solverRoot = $c; $solverExe = $pkgExe; break }
    if (Test-Path $bldExe) { $solverRoot = $c; $solverExe = $bldExe; break }
}

if (-not $solverRoot) {
    Write-Error "Cannot find solver package. Tried: $($candidates -join ', ')"
    Write-Error "Run package_solver.ps1 first, or build with CMake."
    exit 1
}

# Add MSYS2 UCRT64 bin to PATH for DLL resolution
$msys2Ucrt64 = "D:\msys64\ucrt64\bin"
if (Test-Path $msys2Ucrt64) {
    $env:PATH = "$msys2Ucrt64;$env:PATH"
}

# Override OMP_NUM_THREADS if --threads is given
if ($Threads -gt 0) {
    $env:OMP_NUM_THREADS = "$Threads"
}

# Handle --help / --version
if ($Help) {
    & $solverExe --help 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "AESimFM v2.0 solver"
        Write-Host "Usage: solver <jobname>"
        Write-Host "       solver -i <jobname>"
        Write-Host "       solver --threads N <jobname>"
        Write-Host "       solver --help"
        Write-Host "       solver --version"
    }
    exit 0
}

if ($Version) {
    & $solverExe --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "AESimFM v2.0"
    }
    exit 0
}

# Determine job name: -i flag takes precedence over positional
$job = if ($i) { $i } else { $JobName }
if (-not $job) {
    Write-Error "Usage: solver <jobname> or solver -i <jobname>"
    exit 1
}

# Strip .inp suffix if present
$job = $job -replace '\.inp$', ''

Write-Host "AESimFM solver: job=$job  exe=$solverExe"
if ($Threads -gt 0) { Write-Host "  threads=$Threads" }
& $solverExe -i $job @args
exit $LASTEXITCODE

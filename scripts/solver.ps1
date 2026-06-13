<#
.SYNOPSIS
    AESimFM v2.0 solver wrapper — forwards to the self-contained package/bin.
.DESCRIPTION
    This is a legacy convenience script. The canonical way to run the solver
    is via package\bin\solver.cmd (CMD) or package\bin\solver.ps1 (PowerShell),
    both of which are self-contained (no MSYS2 PATH needed).

    To make `solver` available globally:
        .\scripts\install_solver.ps1

    Usage:
        solver disk
        solver -i disk
        solver --help
        solver --version
        solver --threads 8 disk
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

# Locate the packaged solver
$repoRoot = Split-Path -Parent $PSScriptRoot
$pkgSolver = Join-Path $repoRoot "package\bin\solver.exe"

if (-not (Test-Path $pkgSolver)) {
    Write-Error "Packaged solver not found: $pkgSolver"
    Write-Error "Run .\scripts\package_solver.ps1 first."
    exit 1
}

# package\bin is self-contained — add it to PATH for DLL resolution
$pkgBin = Join-Path $repoRoot "package\bin"
$env:PATH = "$pkgBin;$env:PATH"

# Pass --threads through solver.exe (it supports --threads N natively)
if ($Threads -gt 0) {
    $env:OMP_NUM_THREADS = "$Threads"
}

# Handle --help / --version
if ($Help) {
    & $pkgSolver --help 2>$null
    exit $LASTEXITCODE
}

if ($Version) {
    & $pkgSolver --version 2>$null
    exit $LASTEXITCODE
}

# Determine job name
$job = if ($i) { $i } else { $JobName }
if (-not $job) {
    Write-Error "Usage: solver <jobname> or solver -i <jobname>"
    Write-Error "       solver --help"
    Write-Error "       solver --version"
    exit 1
}

$job = $job -replace '\.inp$', ''

Write-Host "AESimFM solver: job=$job"
& $pkgSolver -i $job
exit $LASTEXITCODE

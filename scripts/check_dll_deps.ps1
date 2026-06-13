param(
    [string]$SolverPath = "build\src\solver\solver.exe",
    [string]$MSYS2Root = "D:\msys64",
    [switch]$PassThru
)

$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent $PSScriptRoot
$solverExe = Join-Path $ROOT $SolverPath

if (-not (Test-Path $solverExe)) {
    Write-Error "solver.exe not found: $solverExe"
    exit 1
}

$ucrt64Dir = Join-Path $MSYS2Root "ucrt64\bin"

$requiredDlls = @(
    "libgfortran-5.dll",
    "libgomp-1.dll",
    "libwinpthread-1.dll",
    "libgcc_s_seh-1.dll",
    "libquadmath-0.dll",
    "libatomic-1.dll"
)

$missing = @()
$found = @()

foreach ($dll in $requiredDlls) {
    $path = Join-Path $ucrt64Dir $dll
    if (Test-Path $path) {
        $found += $path
    } else {
        $missing += $dll
    }
}

Write-Host "check_dll_deps: solver = $solverExe"
Write-Host "check_dll_deps: MSYS2  = $MSYS2Root"
Write-Host ""

if ($missing.Count -gt 0) {
    Write-Host "MISSING runtime DLLs (not found in $ucrt64Dir):"
    foreach ($dll in $missing) {
        Write-Host "  MISSING: $dll"
    }
    Write-Host ""
    Write-Host "HINT: Install the missing packages in MSYS2 UCRT64:"
    Write-Host "  pacman -S mingw-w64-ucrt-x86_64-gcc-libs mingw-w64-ucrt-x86_64-gcc-fortran"
    exit 1
}

Write-Host "All runtime DLLs found."
foreach ($dll in $found) {
    Write-Host "  OK: $dll"
}

if ($PassThru) {
    return @{ Found = $found; Missing = $missing; Ucrt64Dir = $ucrt64Dir }
}

exit 0

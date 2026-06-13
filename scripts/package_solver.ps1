param(
    [string]$SolverPath = "build\src\solver\solver.exe",
    [string]$MSYS2Root = "D:\msys64",
    [string]$OutputDir = "package"
)

$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent $PSScriptRoot

# Source paths
$solverExe = Join-Path $ROOT $SolverPath
$ucrt64Bin = Join-Path $MSYS2Root "ucrt64\bin"

if (-not (Test-Path $solverExe)) {
    Write-Error "solver.exe not found: $solverExe"
    exit 1
}

# Create package directory
$packageDir = Join-Path $ROOT $OutputDir
$packageBin = Join-Path $packageDir "bin"
if (-not (Test-Path $packageBin)) {
    New-Item -ItemType Directory -Path $packageBin -Force | Out-Null
}

# DLLs required at runtime
$requiredDlls = @(
    "libgfortran-5.dll",
    "libgomp-1.dll",
    "libwinpthread-1.dll",
    "libgcc_s_seh-1.dll"
)

Write-Host "=== AESimFM v2.0 Solver Packaging ==="
Write-Host "Source : $solverExe"
Write-Host "Target : $packageBin"
Write-Host ""

# Copy solver.exe
$solverDest = Join-Path $packageBin "solver.exe"
Copy-Item $solverExe -Destination $solverDest -Force
$solverSize = [math]::Round((Get-Item $solverDest).Length / 1MB, 2)
Write-Host "  OK: solver.exe ($solverSize MB)"

# Copy runtime DLLs
foreach ($dll in $requiredDlls) {
    $src = Join-Path $ucrt64Bin $dll
    if (-not (Test-Path $src)) {
        Write-Error "DLL not found: $src"
        exit 1
    }
    $dst = Join-Path $packageBin $dll
    Copy-Item $src -Destination $dst -Force
    $dllSize = [math]::Round((Get-Item $dst).Length / 1MB, 2)
    Write-Host "  OK: $dll ($dllSize MB)"
}

# Write DLL manifest
$manifest = Join-Path $packageDir "DLL_MANIFEST.txt"
@"
AESimFM v2.0 Solver Runtime DLL Manifest
========================================
Build: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source: MSYS2 UCRT64 ($MSYS2Root)

Runtime DLLs (copied from $ucrt64Bin):
"@ | Out-File $manifest -Encoding utf8

foreach ($dll in $requiredDlls) {
    $src = Join-Path $ucrt64Bin $dll
    $ver = (Get-Item $src).LastWriteTime.ToString("yyyy-MM-dd HH:mm")
    "  $dll  (UCRT64, $ver)" | Out-File $manifest -Encoding utf8 -Append
}

Write-Host ""
Write-Host "=== Package complete ==="
Write-Host "  $packageBin\solver.exe"
Write-Host ""
Write-Host "Runtime test:"
Write-Host "  cd D:\AESimFM_win\test\inputs"
Write-Host "  $packageBin\solver.exe disk"
exit 0

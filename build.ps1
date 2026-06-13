param(
    [switch]$Clean,
    [switch]$SolverOnly,
    [switch]$Debug,
    [string]$BuildDir = "build",
    [switch]$UseSPOOLES,
    [switch]$NoHDF5,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
AESimFM v2.0 Windows Build Script

Usage: .\build.ps1 [options]

Options:
  -Clean         Clean build directory before building
  -SolverOnly    Build solver only (no remesh tests)
  -Debug         Debug build (default: Release)
  -BuildDir DIR  Build directory name (default: build)
  -UseSPOOLES    Use SPOOLES instead of MUMPS
  -NoHDF5        Disable HDF5 output (FRD only)
  -Help           Show this help

Examples:
  .\build.ps1                        # Default build (MUMPS + HDF5)
  .\build.ps1 -Clean                 # Clean rebuild
  .\build.ps1 -UseSPOOLES -NoHDF5    # Legacy-compatible build
  .\build.ps1 -Debug                 # Debug build
"@
    return
}

$BASH = "D:\msys64\usr\bin\bash.exe"
$WIN_ROOT = "/d/AESimFM_win"
$BUILD_TYPE = if ($Debug) { "Debug" } else { "Release" }

Write-Host "========================================"
Write-Host " AESimFM v2.0 Build"
Write-Host "========================================"
Write-Host " Build Type : $BUILD_TYPE"
Write-Host " MUMPS      : $(if ($UseSPOOLES) { 'OFF (SPOOLES)' } else { 'ON' })"
Write-Host " HDF5       : $(if ($NoHDF5) { 'OFF (FRD only)' } else { 'ON' })"
Write-Host "========================================"
Write-Host ""

# Verify MSYS2 environment
if (-not (Test-Path $BASH)) {
    Write-Error "MSYS2 bash not found at $BASH"
    exit 1
}

# Verify project directory
if (-not (Test-Path "D:\AESimFM_win\CMakeLists.txt")) {
    Write-Error "D:\AESimFM_win\CMakeLists.txt not found"
    exit 1
}

# Clean if requested
if ($Clean) {
    Write-Host "Cleaning build directory..."
    if (Test-Path "D:\AESimFM_win\$BuildDir") {
        Remove-Item -Recurse -Force "D:\AESimFM_win\$BuildDir"
    }
}

# CMake configure
Write-Host "Configuring CMake..."
$cmakeArgs = @(
    "-B", $BuildDir,
    "-G", "MSYS Makefiles",
    "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
)
if ($UseSPOOLES) {
    $cmakeArgs += "-DUSE_MUMPS=OFF"
    $cmakeArgs += "-DUSE_SPOOLES=ON"
}
if ($NoHDF5) {
    $cmakeArgs += "-DOUTPUT_HDF5=OFF"
    $cmakeArgs += "-DOUTPUT_FRD=ON"
}

$cmakeArgsStr = $cmakeArgs -join " "
$configureCmd = "cd $WIN_ROOT && cmake $cmakeArgsStr 2>&1"
$configureResult = & $BASH -lc $configureCmd
if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake configure failed"
    Write-Host $configureResult
    exit 1
}
Write-Host "CMake configure: OK"

# Build
Write-Host "Building..."
$target = if ($SolverOnly) { "--target solver" } else { "" }
$buildCmd = "cd $WIN_ROOT && cmake --build $BuildDir $target -j 8 2>&1"
$buildResult = & $BASH -lc $buildCmd
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    Write-Host $buildResult
    exit 1
}
Write-Host "Build: OK"

Write-Host ""
Write-Host "========================================"
Write-Host " BUILD COMPLETE"
Write-Host "========================================"
Write-Host " Solver: D:\AESimFM_win\$BuildDir\src\solver\solver.exe"
Write-Host ""
Write-Host " Quick test:"
Write-Host "   cd D:\AESimFM_win\test"
Write-Host "   ..\$BuildDir\src\solver\solver.exe -i disk"
Write-Host "========================================"

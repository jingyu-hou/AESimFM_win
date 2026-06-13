param(
    [string]$SolverPackage = "..\package\bin\solver.exe",
    [string]$InputsDir = "inputs",
    [string]$OutputsDir = "outputs",
    [switch]$Clean,
    [switch]$Help
)

$ErrorActionPreference = "Continue"
$ROOT = Split-Path -Parent $PSScriptRoot
$TEST_DIR = $PSScriptRoot

if ($Help) {
    Write-Host @"
AESimFM v2.0 Smoke Test Runner
==============================
Usage: .\run_tests.ps1 [options]

Options:
  -SolverPackage PATH   Path to solver.exe (default: ..\package\bin\solver.exe)
  -InputsDir DIR        Test inputs directory (default: inputs)
  -OutputsDir DIR       Test outputs directory (default: outputs)
  -Clean                Clean output directory before running
  -Help                 Show this help

Exit codes:
  0 = all tests passed
  1 = one or more tests failed
  2 = setup error (missing solver, missing inputs)
"@
    exit 0
}

# Resolve solver
$solverExe = Join-Path $TEST_DIR $SolverPackage
if (-not (Test-Path $solverExe)) {
    $solverExe = Join-Path $ROOT "build\src\solver\solver.exe"
}
if (-not (Test-Path $solverExe)) {
    Write-Error "SOLVER NOT FOUND: $solverExe"
    Write-Error "Build first: .\build.ps1"
    exit 2
}

# Set up MSYS2 DLL path
$msys2Ucrt64 = "D:\msys64\ucrt64\bin"
if (Test-Path $msys2Ucrt64) {
    $env:PATH = "$msys2Ucrt64;$env:PATH"
}

# Inputs directory
$inputsDir = Join-Path $TEST_DIR $InputsDir
if (-not (Test-Path $inputsDir)) {
    Write-Error "Inputs directory not found: $inputsDir"
    exit 2
}

# Outputs directory
$outputsDir = Join-Path $TEST_DIR $OutputsDir
if ($Clean -and (Test-Path $outputsDir)) {
    Remove-Item -Recurse -Force $outputsDir
}
if (-not (Test-Path $outputsDir)) {
    New-Item -ItemType Directory -Path $outputsDir -Force | Out-Null
}

# Discover test cases: each .inp file in inputs/ is a test
$inpFiles = Get-ChildItem -Path $inputsDir -Filter "*.inp" | Sort-Object Name
if ($inpFiles.Count -eq 0) {
    Write-Error "No .inp files found in $inputsDir"
    exit 2
}

Write-Host "========================================"
Write-Host " AESimFM v2.0 Smoke Tests"
Write-Host "========================================"
Write-Host " Solver : $solverExe"
Write-Host " Inputs : $inputsDir"
Write-Host " Outputs: $outputsDir"
Write-Host " Cases  : $($inpFiles.Count)"
Write-Host "========================================"
Write-Host ""

$passed = 0
$failed = 0
$results = @()

foreach ($inp in $inpFiles) {
    $jobName = $inp.BaseName
    $caseOutputDir = Join-Path $outputsDir $jobName
    if (-not (Test-Path $caseOutputDir)) {
        New-Item -ItemType Directory -Path $caseOutputDir -Force | Out-Null
    }

    # Copy input to output dir (solver works from working directory)
    Copy-Item $inp.FullName -Destination $caseOutputDir -Force

    Write-Host "[RUN] $jobName ... " -NoNewline

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Push-Location $caseOutputDir
    try {
        & $solverExe -i $jobName 2>&1 | Out-Null
        $exitCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    $sw.Stop()
    $elapsed = [math]::Round($sw.Elapsed.TotalSeconds, 1)

    # Verify outputs
    $checks = @{
        ExitCode    = $exitCode -eq 0
        STA_Exists  = Test-Path (Join-Path $caseOutputDir "$jobName.sta")
        FRD_Exists  = Test-Path (Join-Path $caseOutputDir "$jobName.frd")
        FRD_EOF     = $false
        DAT_NoError = $true
    }

    # Check FRD end marker
    $frdPath = Join-Path $caseOutputDir "$jobName.frd"
    if ($checks.FRD_Exists) {
        $frdSize = (Get-Item $frdPath).Length
        if ($frdSize -gt 0) {
            $frdTail = Get-Content $frdPath -Tail 2 -Encoding ASCII -ErrorAction SilentlyContinue
            $checks.FRD_EOF = ($frdTail -match "^\s*9999") -or ($frdSize -gt 1000000)
        }
    }

    # Check DAT for errors
    $datPath = Join-Path $caseOutputDir "$jobName.dat"
    if (Test-Path $datPath) {
        $datContent = Get-Content $datPath -ErrorAction SilentlyContinue
        if ($datContent -match "\*ERROR") {
            $checks.DAT_NoError = $false
        }
    }

    $allPassed = ($checks.ExitCode -and $checks.FRD_Exists -and $checks.FRD_EOF -and $checks.DAT_NoError)

    $result = [PSCustomObject]@{
        Case     = $jobName
        Elapsed  = $elapsed
        Passed   = $allPassed
        ExitCode = $exitCode
        Checks   = $checks
    }
    $results += $result

    if ($allPassed) {
        Write-Host "PASS (${elapsed}s)"
        $passed++
    } else {
        Write-Host "FAIL (${elapsed}s, exit=$exitCode)"
        foreach ($k in $checks.Keys) {
            if (-not $checks[$k]) {
                Write-Host "       check failed: $k"
            }
        }
        $failed++
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host " RESULTS: $passed passed, $failed failed"
Write-Host "========================================"

if ($failed -gt 0) {
    exit 1
}
exit 0

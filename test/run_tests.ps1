<#
.SYNOPSIS
    AESimFM v2.0 Phase 0 smoke test runner.
.DESCRIPTION
    Runs the packaged solver against test inputs and checks outputs.
    No build step — tests the solver as the user would run it.

    Exit: 0 = all passed, 1 = failures, 2 = setup error.

.PARAMETER Full
    Include the full disk.inp regression (2+ hours).
.PARAMETER SolverPath
    Path to solver.exe. Defaults to package/bin/solver.exe.
#>

param(
    [switch]$Full,
    [string]$SolverPath
)

$ErrorActionPreference = "Continue"
$ROOT = Split-Path -Parent $PSScriptRoot
$TestDir = Join-Path $ROOT "test\inputs"

# Locate solver: --SolverPath > package/bin > build
if (-not $SolverPath) {
    $candidates = @(
        (Join-Path $ROOT "package\bin\solver.exe"),
        (Join-Path $ROOT "build\src\solver\solver.exe")
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $SolverPath = $c; break }
    }
}
if (-not $SolverPath -or -not (Test-Path $SolverPath)) {
    Write-Host "FAIL: solver.exe not found. Run package_solver.ps1 or build first."
    exit 2
}

# Self-contained: add package/bin to PATH for DLL resolution
$PkgBin = Split-Path -Parent $SolverPath
$env:PATH = "$PkgBin;$env:PATH"

$Passed = 0
$Failed = 0

function Test-Case {
    param([string]$Name, [scriptblock]$Test)
    Write-Host -NoNewline "  $Name ... "
    try {
        & $Test
        Write-Host "PASS"
        $script:Passed++
    } catch {
        Write-Host "FAIL: $_"
        $script:Failed++
    }
}

Write-Host "=== AESimFM v2.0 Smoke Tests ==="
Write-Host "Solver : $SolverPath"
Write-Host "TestDir: $TestDir"
Write-Host ""

# ── T0: solver --version ──
Test-Case "T0: solver --version returns 0" {
    $out = & $SolverPath --version 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "exit=$LASTEXITCODE" }
    if ($out -notmatch "AESimFM") { throw "unexpected output: $out" }
}

# ── T1: solver --help ──
Test-Case "T1: solver --help returns 0" {
    & $SolverPath --help 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "exit=$LASTEXITCODE" }
}

# ── T2: missing input fails ──
Test-Case "T2: missing input reports error" {
    $errOut = & $SolverPath -i __nonexistent__ 2>&1 | Out-String
    if ($errOut -notmatch "ERROR.*cannot open") { throw "expected error message, got: $errOut" }
}

# ── T3: cax4_elastic ──
$smallJob = "cax4_elastic"
Test-Case "T3: $smallJob produces valid FRD with EOF" {
    Push-Location $TestDir
    try {
        Remove-Item "$smallJob.frd", "$smallJob.sta", "$smallJob.cvg" -Force -ErrorAction SilentlyContinue

        & $SolverPath -i $smallJob 2>&1 | Out-Null
        # exit 1 is OK — signal handler writes FRD footer then _exit(1)
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
            throw "unexpected exit=$LASTEXITCODE"
        }

        if (-not (Test-Path "$smallJob.frd"))  { throw "FRD not generated" }
        if (-not (Test-Path "$smallJob.sta"))  { throw "STA not generated" }
        if (-not (Test-Path "$smallJob.cvg"))  { throw "CVG not generated" }

        $frdEnd = (Get-Content "$smallJob.frd" -Tail 2) -join "`n"
        if ($frdEnd -notmatch "9999") { throw "FRD missing 9999 footer" }

        $frdSize = (Get-Item "$smallJob.frd").Length
        if ($frdSize -lt 100) { throw "FRD too small ($frdSize bytes)" }
    } finally {
        Pop-Location
    }
}

# ── T4: --threads N ──
Test-Case "T4: --threads 2 accepted" {
    Push-Location $TestDir
    try {
        Remove-Item "$smallJob.frd", "$smallJob.sta", "$smallJob.cvg" -Force -ErrorAction SilentlyContinue

        & $SolverPath --threads 2 -i $smallJob 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
            throw "unexpected exit=$LASTEXITCODE"
        }
        if (-not (Test-Path "$smallJob.frd")) { throw "FRD not generated" }
    } finally {
        Pop-Location
    }
}

# ── T5: absurd thread count doesn't crash ──
Test-Case "T5: --threads 99999 handled" {
    Push-Location $TestDir
    try {
        Remove-Item "$smallJob.frd", "$smallJob.sta", "$smallJob.cvg" -Force -ErrorAction SilentlyContinue

        & $SolverPath --threads 99999 -i $smallJob 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
            throw "unexpected exit=$LASTEXITCODE"
        }
        if (-not (Test-Path "$smallJob.frd")) { throw "FRD not generated" }
    } finally {
        Pop-Location
    }
}

# ── T6: disk regression (full only) ──
if ($Full) {
    $diskJob = "disk"
    Test-Case "T6: $diskJob regression" {
        Push-Location $TestDir
        try {
            Remove-Item "$diskJob.frd", "$diskJob.sta", "$diskJob.cvg", "$diskJob.dat" -Force -ErrorAction SilentlyContinue

            Write-Host ""
            Write-Host "    Running disk.inp (2+ hours)..."
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            & $SolverPath -i $diskJob 2>&1 | Out-Null
            $ec = $LASTEXITCODE
            $sw.Stop()

            # disk normally completes with exit 201 (stop.f) or 0
            if ($ec -ne 0 -and $ec -ne 201) { throw "unexpected exit=$ec" }

            if (-not (Test-Path "$diskJob.frd")) { throw "FRD not generated" }
            if (-not (Test-Path "$diskJob.sta")) { throw "STA not generated" }
            if (-not (Test-Path "$diskJob.cvg")) { throw "CVG not generated" }

            $frdMB = [math]::Round((Get-Item "$diskJob.frd").Length / 1MB, 1)
            $staLines = (Get-Content "$diskJob.sta" | Measure-Object).Count
            $min = [math]::Round($sw.Elapsed.TotalMinutes, 1)
            Write-Host "    disk: FRD=${frdMB}MB STA=${staLines}lines time=${min}min"
        } finally {
            Pop-Location
        }
    }
} else {
    Write-Host "  T6: disk regression (skipped; use -Full)"
}

# ── Summary ──
Write-Host ""
Write-Host "=== Results: $Passed passed, $Failed failed ==="

if ($Failed -gt 0) { exit 1 }
exit 0

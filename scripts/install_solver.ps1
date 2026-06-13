<#
.SYNOPSIS
    Install AESimFM solver to user PATH. Run once, then `solver disk` from anywhere.
.DESCRIPTION
    Adds D:\AESimFM_win\package\bin to the user-level PATH environment variable.
    After installation, restart your terminal or run `refreshenv` for the change
    to take effect in existing sessions.
.PARAMETER Scope
    User (default) or Machine. Machine requires admin rights.
.PARAMETER Uninstall
    Remove the solver from PATH instead.
#>

param(
    [ValidateSet("User","Machine")]
    [string]$Scope = "User",

    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

$binDir = Split-Path -Parent $PSScriptRoot
$binDir = Join-Path $binDir "package\bin"

if (-not (Test-Path (Join-Path $binDir "solver.exe"))) {
    Write-Error "solver.exe not found at $binDir. Run package_solver.ps1 first."
    exit 1
}

# Get current PATH for the target scope
$envRegPath = if ($Scope -eq "User") {
    "HKCU:\Environment"
} else {
    "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
}

$currentPath = (Get-ItemProperty -Path $envRegPath -Name PATH).PATH

if ($Uninstall) {
    Write-Host "Removing solver from $Scope PATH..."
    $newPath = ($currentPath -split ';' | Where-Object { $_ -ne $binDir }) -join ';'
    Set-ItemProperty -Path $envRegPath -Name PATH -Value $newPath
    Write-Host "Done. Close and reopen your terminal for the change to take effect."
    exit 0
}

# Check if already installed
if ($currentPath -split ';' -contains $binDir) {
    Write-Host "Solver already in $Scope PATH: $binDir"
    Write-Host ""
    Write-Host "If `solver` is not found, restart your terminal."
    exit 0
}

# Add to PATH
Write-Host "Adding solver to $Scope PATH..."
Write-Host "  $binDir"
$newPath = "$currentPath;$binDir"
Set-ItemProperty -Path $envRegPath -Name PATH -Value $newPath

# Also update current session
$env:PATH = "$env:PATH;$binDir"

Write-Host ""
Write-Host "Installation complete."
Write-Host "  Run 'solver disk' from any directory to test."
Write-Host ""
Write-Host "Note: Existing terminal windows need to be restarted,"
Write-Host "or run: `$env:PATH = [Environment]::GetEnvironmentVariable('PATH','$Scope')"
Write-Host ""
Write-Host "To uninstall: .\install_solver.ps1 -Uninstall"
exit 0

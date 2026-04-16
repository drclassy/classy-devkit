# validate.ps1 — Avvcenna+ DevKit Setup Validator
# Compatible: Windows PowerShell 5.1+
#
# Checks whether a target project has the avvcenna-devkit setup correctly installed.
# Reports missing items as warnings, not hard errors. Exit code 0 always.
#
# Usage:
#   .\scripts\validate.ps1                    # validate current directory
#   .\scripts\validate.ps1 -target ../my-repo # validate specific directory

param(
    [string]$target = "."
)

$TargetPath = Resolve-Path $target -ErrorAction Stop
$Separator = "=" * 60
$Passed = 0
$Warnings = 0

function Check-Exists {
    param([string]$File, [string]$Label, [string]$Hint = "")
    $FullPath = Join-Path $TargetPath $File
    if (Test-Path $FullPath) {
        Write-Host "  [OK] $Label" -ForegroundColor Green
        $script:Passed++
    } else {
        Write-Host "  [!!] $Label — missing" -ForegroundColor Yellow
        if ($Hint) { Write-Host "       $Hint" -ForegroundColor DarkGray }
        $script:Warnings++
    }
}

function Check-ValidJson {
    param([string]$File, [string]$Label)
    $FullPath = Join-Path $TargetPath $File
    if (-not (Test-Path $FullPath)) {
        Write-Host "  [!!] $Label — file not found" -ForegroundColor Yellow
        $script:Warnings++
        return
    }
    try {
        Get-Content $FullPath -Raw | ConvertFrom-Json | Out-Null
        Write-Host "  [OK] $Label — valid JSON" -ForegroundColor Green
        $script:Passed++
    } catch {
        Write-Host "  [ERR] $Label — invalid JSON: $_" -ForegroundColor Red
        $script:Warnings++
    }
}

Write-Host ""
Write-Host $Separator -ForegroundColor DarkGray
Write-Host "  avvcenna-devkit validate" -ForegroundColor White
Write-Host "  Target: $TargetPath" -ForegroundColor DarkGray
Write-Host $Separator -ForegroundColor DarkGray
Write-Host ""
Write-Host "  GitHub Actions Workflows" -ForegroundColor White

Check-Exists ".github\workflows\ci.yml"            "CI workflow"           "Run: generate.ps1 -target $TargetPath"
Check-Exists ".github\workflows\security-scan.yml" "Security scan workflow"
Check-Exists ".github\workflows\auto-fix.yml"      "Auto-fix workflow"
Check-Exists ".github\workflows\auto-merge.yml"    "Auto-merge workflow"

Write-Host ""
Write-Host "  Dependency Management" -ForegroundColor White

Check-ValidJson "renovate.json" "renovate.json"

Write-Host ""
Write-Host "  Git Hooks" -ForegroundColor White

Check-Exists ".git\hooks\pre-push"     "pre-push hook (wrapper)"   "Run: generate.ps1 -target $TargetPath"
Check-Exists ".git\hooks\pre-push.ps1" "pre-push.ps1 (Windows)"
Check-Exists ".git\hooks\pre-push.sh"  "pre-push.sh (Linux/Mac)"

Write-Host ""
Write-Host $Separator -ForegroundColor DarkGray

if ($Warnings -eq 0) {
    Write-Host "  All $Passed checks passed. Setup looks correct." -ForegroundColor Green
} else {
    Write-Host "  $Passed passed, $Warnings warning(s). Run generate.ps1 to fix missing items." -ForegroundColor Yellow
}

Write-Host $Separator -ForegroundColor DarkGray
Write-Host ""

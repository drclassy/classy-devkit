# sync.ps1 — Avvcenna+ DevKit Template Sync
# Compatible: Windows PowerShell 5.1+
#
# Updates workflow files and renovate.json in an existing project from the
# latest avvcenna-devkit templates. Does NOT touch pre-push hooks (to avoid
# disrupting local customizations).
#
# Usage:
#   .\scripts\sync.ps1 -target ../my-existing-repo
#   .\scripts\sync.ps1 -target ../my-existing-repo -force  # overwrite all

param(
    [Parameter(Mandatory = $true)]
    [string]$target,

    [switch]$force
)

$ErrorActionPreference = "Stop"
$TemplateRoot = Split-Path -Parent $PSScriptRoot
$Separator = "=" * 60

function Write-Step  { param([string]$m) Write-Host "  >> $m" -ForegroundColor Cyan }
function Write-Done  { param([string]$m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Warn  { param([string]$m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Skip  { param([string]$m) Write-Host "  [--] $m" -ForegroundColor DarkGray }

Write-Host ""
Write-Host $Separator -ForegroundColor DarkGray
Write-Host "  avvcenna-devkit sync" -ForegroundColor White
Write-Host $Separator -ForegroundColor DarkGray

# ─── 1. Resolve target ────────────────────────────────────────────────────────
if (-not (Test-Path $target)) {
    Write-Host "  ERROR: Target does not exist: $target" -ForegroundColor Red
    exit 1
}

$TargetPath = Resolve-Path $target
Write-Done "Target: $TargetPath"

# ─── 2. Sync workflow files ───────────────────────────────────────────────────
Write-Step "Syncing GitHub Actions workflows"

$WorkflowSrc = Join-Path $TemplateRoot "templates\github\workflows"
$WorkflowDst = Join-Path $TargetPath ".github\workflows"

if (-not (Test-Path $WorkflowDst)) {
    Write-Warn ".github/workflows not found in target — creating it"
    New-Item -ItemType Directory -Path $WorkflowDst -Force | Out-Null
}

$Updated = 0
$Skipped = 0

Get-ChildItem -Path $WorkflowSrc -Filter "*.yml" | ForEach-Object {
    $Dst = Join-Path $WorkflowDst $_.Name

    if ((Test-Path $Dst) -and -not $force) {
        # Compare checksums — only update if content changed
        $SrcHash = (Get-FileHash $_.FullName -Algorithm MD5).Hash
        $DstHash = (Get-FileHash $Dst -Algorithm MD5).Hash

        if ($SrcHash -eq $DstHash) {
            Write-Skip "$($_.Name) — already up to date"
            $Skipped++
        } else {
            Copy-Item -Path $_.FullName -Destination $Dst -Force
            Write-Done "Updated $($_.Name)"
            $Updated++
        }
    } else {
        Copy-Item -Path $_.FullName -Destination $Dst -Force
        Write-Done "Synced $($_.Name)"
        $Updated++
    }
}

# ─── 3. Sync renovate.json ────────────────────────────────────────────────────
Write-Step "Syncing renovate.json"

$RenovateSrc = Join-Path $TemplateRoot "renovate.json"
$RenovateDst = Join-Path $TargetPath "renovate.json"

if ((Test-Path $RenovateDst) -and -not $force) {
    $SrcHash = (Get-FileHash $RenovateSrc -Algorithm MD5).Hash
    $DstHash = (Get-FileHash $RenovateDst -Algorithm MD5).Hash

    if ($SrcHash -eq $DstHash) {
        Write-Skip "renovate.json — already up to date"
        $Skipped++
    } else {
        Copy-Item -Path $RenovateSrc -Destination $RenovateDst -Force
        Write-Done "Updated renovate.json"
        $Updated++
    }
} else {
    Copy-Item -Path $RenovateSrc -Destination $RenovateDst -Force
    Write-Done "Synced renovate.json"
    $Updated++
}

# ─── 4. Summary ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host $Separator -ForegroundColor DarkGray
Write-Host "  Sync complete: $Updated updated, $Skipped already current" -ForegroundColor Green
Write-Host "  Note: Pre-push hooks were NOT synced (preserve local changes)" -ForegroundColor DarkGray
Write-Host "  Use generate.ps1 -force to reinstall hooks" -ForegroundColor DarkGray
Write-Host $Separator -ForegroundColor DarkGray
Write-Host ""

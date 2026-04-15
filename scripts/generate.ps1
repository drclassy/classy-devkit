# generate.ps1 — Claudesy DevKit Project Initializer
# Compatible: Windows PowerShell 5.1+
#
# Copies all claudesy-devkit template files into a target project directory.
# Auto-detects the project stack, or accept an explicit -stack override.
#
# Usage:
#   .\scripts\generate.ps1 -target ../my-new-repo
#   .\scripts\generate.ps1 -target ../my-new-repo -stack NEXTJS
#   .\scripts\generate.ps1 -target ../my-new-repo -stack TURBOREPO -force

param(
    [Parameter(Mandatory = $true)]
    [string]$target,

    [ValidateSet("TURBOREPO", "NEXTJS", "NESTJS", "NODE", "")]
    [string]$stack = "",

    [switch]$force
)

$ErrorActionPreference = "Stop"
$TemplateRoot = Split-Path -Parent $PSScriptRoot
$Separator = "=" * 60

function Write-Step  { param([string]$m) Write-Host "  >> $m" -ForegroundColor Cyan }
function Write-Done  { param([string]$m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Warn  { param([string]$m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Error2 { param([string]$m) Write-Host "  [ERR] $m" -ForegroundColor Red }

Write-Host ""
Write-Host $Separator -ForegroundColor DarkGray
Write-Host "  claudesy-devkit generate" -ForegroundColor White
Write-Host $Separator -ForegroundColor DarkGray

# ─── 1. Resolve target path ───────────────────────────────────────────────────
Write-Step "Resolving target: $target"

if (-not (Test-Path $target)) {
    Write-Warn "Target directory does not exist — creating it"
    New-Item -ItemType Directory -Path $target -Force | Out-Null
}

$TargetPath = Resolve-Path $target

Write-Done "Target: $TargetPath"

# ─── 2. Detect stack ──────────────────────────────────────────────────────────
Write-Step "Detecting stack"

if ($stack -ne "") {
    $StackType = $stack.ToUpper()
    Write-Done "Stack (override): $StackType"
} else {
    $StackType = & "$PSScriptRoot\detect-stack.ps1" -path $TargetPath
    Write-Done "Stack (detected): $StackType"
}

# ─── 3. Load manifest ─────────────────────────────────────────────────────────
Write-Step "Loading manifest for $StackType"

$ManifestFile = Join-Path $TemplateRoot "manifests\$($StackType.ToLower()).json"
$Manifest = @{}

if (Test-Path $ManifestFile) {
    $Manifest = Get-Content $ManifestFile -Raw | ConvertFrom-Json -AsHashtable
    Write-Done "Manifest loaded: $ManifestFile"
} else {
    Write-Warn "No manifest for $StackType — using defaults"
}

# ─── 4. Copy workflow files ───────────────────────────────────────────────────
Write-Step "Copying GitHub Actions workflows"

$WorkflowSrc = Join-Path $TemplateRoot "templates\github\workflows"
$WorkflowDst = Join-Path $TargetPath ".github\workflows"

if (-not (Test-Path $WorkflowDst)) {
    New-Item -ItemType Directory -Path $WorkflowDst -Force | Out-Null
}

Get-ChildItem -Path $WorkflowSrc -Filter "*.yml" | ForEach-Object {
    $Dst = Join-Path $WorkflowDst $_.Name

    if ((Test-Path $Dst) -and -not $force) {
        Write-Warn "Skipping $($_.Name) — already exists (use -force to overwrite)"
    } else {
        Copy-Item -Path $_.FullName -Destination $Dst -Force
        Write-Done "Copied $($_.Name)"
    }
}

# ─── 5. Copy renovate.json ────────────────────────────────────────────────────
Write-Step "Copying renovate.json"

$RenovateSrc = Join-Path $TemplateRoot "renovate.json"
$RenovateDst = Join-Path $TargetPath "renovate.json"

if ((Test-Path $RenovateDst) -and -not $force) {
    Write-Warn "Skipping renovate.json — already exists (use -force to overwrite)"
} else {
    Copy-Item -Path $RenovateSrc -Destination $RenovateDst -Force
    Write-Done "Copied renovate.json"
}

# ─── 6. Install pre-push hooks ────────────────────────────────────────────────
Write-Step "Installing pre-push hooks"

$GitHooksDir = Join-Path $TargetPath ".git\hooks"

if (-not (Test-Path $GitHooksDir)) {
    Write-Warn ".git/hooks not found — is $TargetPath a git repository?"
    Write-Warn "Skipping hook installation. Run 'git init' first, then re-run generate.ps1"
} else {
    $HookSrcPs1 = Join-Path $TemplateRoot "templates\hooks\pre-push.ps1"
    $HookSrcSh  = Join-Path $TemplateRoot "templates\hooks\pre-push.sh"

    # Windows: copy .ps1 as the hook caller wrapper
    $HookDst = Join-Path $GitHooksDir "pre-push"

    # Write a bash-compatible wrapper that calls the PowerShell script
    $HookWrapper = @"
#!/usr/bin/env bash
# claudesy-devkit pre-push hook wrapper
# Calls pre-push.ps1 on Windows, pre-push.sh on Linux/Mac

if command -v pwsh &> /dev/null; then
    pwsh -NoProfile -ExecutionPolicy Bypass -File "\$(git rev-parse --git-dir)/hooks/pre-push.ps1" "\$@"
elif command -v powershell &> /dev/null; then
    powershell -NoProfile -ExecutionPolicy Bypass -File "\$(git rev-parse --git-dir)/hooks/pre-push.ps1" "\$@"
else
    bash "\$(git rev-parse --git-dir)/hooks/pre-push.sh" "\$@"
fi
"@
    $HookWrapper | Out-File -FilePath $HookDst -Encoding utf8 -NoNewline
    Copy-Item -Path $HookSrcPs1 -Destination (Join-Path $GitHooksDir "pre-push.ps1") -Force
    Copy-Item -Path $HookSrcSh  -Destination (Join-Path $GitHooksDir "pre-push.sh")  -Force

    Write-Done "Installed pre-push (wrapper + .ps1 + .sh)"
}

# ─── 7. Summary ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host $Separator -ForegroundColor DarkGray
Write-Host "  claudesy-devkit setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Target  : $TargetPath" -ForegroundColor White
Write-Host "  Stack   : $StackType" -ForegroundColor White
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "  1. Add required secrets to GitHub repo settings:" -ForegroundColor DarkGray
Write-Host "     - SEMGREP_APP_TOKEN (optional, for Semgrep dashboard)" -ForegroundColor DarkGray
Write-Host "     - SNYK_TOKEN        (optional, for Snyk vulnerability scan)" -ForegroundColor DarkGray
Write-Host "  2. Enable Renovate on https://github.com/apps/renovate" -ForegroundColor DarkGray
Write-Host "  3. Push to GitHub and watch CI run" -ForegroundColor DarkGray
Write-Host $Separator -ForegroundColor DarkGray
Write-Host ""

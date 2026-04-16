# pre-push.ps1 — Avvcenna+ DevKit Pre-Push Hook
# Compatible: Windows PowerShell 5.1+
#
# Install: Copy to .git/hooks/pre-push (no extension) and ensure it's called
# from a wrapper. Or use generate.ps1 which sets this up automatically.
#
# What this checks before every git push:
#   1. Prettier format check (if config exists)
#   2. ESLint lint (if config exists)
#   3. TypeScript typecheck — tsc --noEmit (if tsconfig.json exists)
#
# Exit 1 = block push. Exit 0 = allow push.

param(
    [string]$remote,
    [string]$url
)

$ErrorCount = 0
$Separator = "=" * 60

function Write-Step {
    param([string]$Name)
    Write-Host ""
    Write-Host "  >> $Name" -ForegroundColor Cyan
}

function Write-Pass {
    param([string]$Name)
    Write-Host "  [PASS] $Name" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Name)
    Write-Host "  [FAIL] $Name" -ForegroundColor Red
}

Write-Host ""
Write-Host $Separator -ForegroundColor DarkGray
Write-Host "  avvcenna-devkit pre-push checks" -ForegroundColor White
Write-Host $Separator -ForegroundColor DarkGray

# ─── 1. Prettier Format Check ─────────────────────────────────────────────────
$PrettierConfig = (Test-Path ".prettierrc") -or
                  (Test-Path ".prettierrc.json") -or
                  (Test-Path ".prettierrc.js") -or
                  (Test-Path ".prettierrc.ts") -or
                  (Test-Path ".prettierrc.yaml") -or
                  (Test-Path ".prettierrc.yml") -or
                  (Test-Path "prettier.config.js") -or
                  (Test-Path "prettier.config.ts") -or
                  (Test-Path "prettier.config.mjs")

if ($PrettierConfig) {
    Write-Step "Prettier format check"
    npx prettier --check . --ignore-unknown 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Prettier — run 'npx prettier --write .' to fix"
        $ErrorCount++
    } else {
        Write-Pass "Prettier"
    }
} else {
    Write-Host "  [SKIP] Prettier — no config found" -ForegroundColor DarkGray
}

# ─── 2. ESLint ────────────────────────────────────────────────────────────────
$EslintConfig = (Test-Path ".eslintrc") -or
                (Test-Path ".eslintrc.js") -or
                (Test-Path ".eslintrc.cjs") -or
                (Test-Path ".eslintrc.json") -or
                (Test-Path ".eslintrc.yaml") -or
                (Test-Path ".eslintrc.yml") -or
                (Test-Path "eslint.config.js") -or
                (Test-Path "eslint.config.mjs") -or
                (Test-Path "eslint.config.ts")

if ($EslintConfig) {
    Write-Step "ESLint"
    npx eslint . --max-warnings=0 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "ESLint — run 'npx eslint . --fix' to auto-fix where possible"
        $ErrorCount++
    } else {
        Write-Pass "ESLint"
    }
} else {
    Write-Host "  [SKIP] ESLint — no config found" -ForegroundColor DarkGray
}

# ─── 3. TypeScript Typecheck ──────────────────────────────────────────────────
if (Test-Path "tsconfig.json") {
    Write-Step "TypeScript typecheck (tsc --noEmit)"
    npx tsc --noEmit 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "TypeScript — fix type errors before pushing"
        $ErrorCount++
    } else {
        Write-Pass "TypeScript"
    }
} else {
    Write-Host "  [SKIP] TypeScript — no tsconfig.json found" -ForegroundColor DarkGray
}

# ─── Result ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host $Separator -ForegroundColor DarkGray

if ($ErrorCount -gt 0) {
    Write-Host "  BLOCKED: $ErrorCount check(s) failed. Fix errors before pushing." -ForegroundColor Red
    Write-Host $Separator -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

Write-Host "  All checks passed. Push allowed." -ForegroundColor Green
Write-Host $Separator -ForegroundColor DarkGray
Write-Host ""
exit 0

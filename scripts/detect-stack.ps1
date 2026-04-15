# detect-stack.ps1 — Claudesy DevKit Stack Detector
# Compatible: Windows PowerShell 5.1+
#
# Detects the project stack type from files in the target directory.
# Sets $env:STACK_TYPE and writes to .stack-type for consumption by other scripts.
#
# Usage:
#   .\scripts\detect-stack.ps1                     # detect in current dir
#   .\scripts\detect-stack.ps1 -path ../my-project # detect in specific dir
#
# Stack types:
#   TURBOREPO  — turbo.json found
#   NEXTJS     — next.config.js / next.config.ts / next.config.mjs found
#   NESTJS     — nest-cli.json found
#   NODE       — default fallback

param(
    [string]$path = "."
)

$TargetPath = Resolve-Path $path -ErrorAction Stop

function Detect-Stack {
    param([string]$Dir)

    # Order matters: check Turborepo first (it may contain Next.js inside)
    if (Test-Path (Join-Path $Dir "turbo.json")) {
        return "TURBOREPO"
    }

    if ((Test-Path (Join-Path $Dir "next.config.js")) -or
        (Test-Path (Join-Path $Dir "next.config.ts")) -or
        (Test-Path (Join-Path $Dir "next.config.mjs"))) {
        return "NEXTJS"
    }

    if (Test-Path (Join-Path $Dir "nest-cli.json")) {
        return "NESTJS"
    }

    return "NODE"
}

$StackType = Detect-Stack -Dir $TargetPath

# Set environment variable for current session (consumed by generate.ps1)
$env:STACK_TYPE = $StackType

# Write to file so other scripts can read it without re-detecting
$StackFile = Join-Path $TargetPath ".stack-type"
$StackType | Out-File -FilePath $StackFile -Encoding utf8 -NoNewline

Write-Host "Stack detected: $StackType" -ForegroundColor Cyan
Write-Host "Written to: $StackFile" -ForegroundColor DarkGray

return $StackType

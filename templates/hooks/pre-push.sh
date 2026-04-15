#!/usr/bin/env bash
# pre-push.sh — Claudesy DevKit Pre-Push Hook
# Compatible: bash, sh (Linux/Mac/CI)
#
# Install: Copy to .git/hooks/pre-push and chmod +x .git/hooks/pre-push
# Or use generate.ps1 / generate.sh which sets this up automatically.
#
# What this checks before every git push:
#   1. Prettier format check (if config exists)
#   2. ESLint lint (if config exists)
#   3. TypeScript typecheck — tsc --noEmit (if tsconfig.json exists)
#
# Exit 1 = block push. Exit 0 = allow push.

set -e

ERROR_COUNT=0
SEP="============================================================"

step()  { echo ""; echo "  >> $1"; }
pass()  { echo "  [PASS] $1"; }
fail()  { echo "  [FAIL] $1"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
skip()  { echo "  [SKIP] $1"; }

echo ""
echo "$SEP"
echo "  claudesy-devkit pre-push checks"
echo "$SEP"

# ─── Helper: check if prettier config exists ──────────────────────────────────
has_prettier_config() {
    [ -f ".prettierrc" ] || \
    [ -f ".prettierrc.json" ] || \
    [ -f ".prettierrc.js" ] || \
    [ -f ".prettierrc.ts" ] || \
    [ -f ".prettierrc.yaml" ] || \
    [ -f ".prettierrc.yml" ] || \
    [ -f "prettier.config.js" ] || \
    [ -f "prettier.config.ts" ] || \
    [ -f "prettier.config.mjs" ]
}

# ─── Helper: check if eslint config exists ────────────────────────────────────
has_eslint_config() {
    [ -f ".eslintrc" ] || \
    [ -f ".eslintrc.js" ] || \
    [ -f ".eslintrc.cjs" ] || \
    [ -f ".eslintrc.json" ] || \
    [ -f ".eslintrc.yaml" ] || \
    [ -f ".eslintrc.yml" ] || \
    [ -f "eslint.config.js" ] || \
    [ -f "eslint.config.mjs" ] || \
    [ -f "eslint.config.ts" ]
}

# ─── 1. Prettier Format Check ─────────────────────────────────────────────────
if has_prettier_config; then
    step "Prettier format check"
    if npx prettier --check . --ignore-unknown > /dev/null 2>&1; then
        pass "Prettier"
    else
        fail "Prettier — run 'npx prettier --write .' to fix"
    fi
else
    skip "Prettier — no config found"
fi

# ─── 2. ESLint ────────────────────────────────────────────────────────────────
if has_eslint_config; then
    step "ESLint"
    if npx eslint . --max-warnings=0 > /dev/null 2>&1; then
        pass "ESLint"
    else
        fail "ESLint — run 'npx eslint . --fix' to auto-fix where possible"
    fi
else
    skip "ESLint — no config found"
fi

# ─── 3. TypeScript Typecheck ──────────────────────────────────────────────────
if [ -f "tsconfig.json" ]; then
    step "TypeScript typecheck (tsc --noEmit)"
    if npx tsc --noEmit > /dev/null 2>&1; then
        pass "TypeScript"
    else
        fail "TypeScript — fix type errors before pushing"
    fi
else
    skip "TypeScript — no tsconfig.json found"
fi

# ─── Result ───────────────────────────────────────────────────────────────────
echo ""
echo "$SEP"

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "  BLOCKED: $ERROR_COUNT check(s) failed. Fix errors before pushing."
    echo "$SEP"
    echo ""
    exit 1
fi

echo "  All checks passed. Push allowed."
echo "$SEP"
echo ""
exit 0

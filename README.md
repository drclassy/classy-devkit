# claudesy-devkit

Git workflow scaffold for all Claudesy organization projects.

**Description:** Every new Claudesy repository requires identical CI pipelines, security scanning, dependency automation, and pre-push hooks — but manually configuring each repo is expensive and inconsistent. `claudesy-devkit` solves this with a single command: auto-detect your stack, copy all template files, and install hooks. Extracted from the proven automation stack in `abyss-monorepo`.  
**Principle:** Deterministic tools, minimum agents, maximum coverage. Artificial Intelligence for judgment — not for routine CI.

---

## 🚀 Quickstart (5 minutes)

### 1. Clone the repo

```powershell
git clone https://github.com/Docsynapse/claudesy-devkit.git
cd claudesy-devkit
```

### 2. Initialize a new project

```powershell
.\scripts\generate.ps1 -target ../my-new-repo
```

This script will:
- Auto-detect your stack (Turborepo / Next.js / NestJS / Node)
- Copy all workflow files to `.github/workflows/` and `renovate.json`
- Install pre-push hooks (format + lint + typecheck)

### 3. Push and watch CI run

```bash
cd ../my-new-repo
git add .github/ renovate.json
git commit -m "chore: add claudesy-devkit CI scaffold"
git push
```

### 4. Configure secrets (recommended)

| Secret | Purpose | Required? |
|--------|---------|-----------|
| `SEMGREP_APP_TOKEN` | Semgrep dashboard & PR comments | Optional |
| `SNYK_TOKEN` | Snyk vulnerability scan | Optional |
| `TURBO_TOKEN` | Turborepo remote cache | Turborepo only |
| `TURBO_TEAM` | Turborepo team identifier | Turborepo only |

**How to set:** GitHub → Settings → Secrets and variables → Actions

### 5. Enable Renovate (automated dependency updates)

Install the app: https://github.com/apps/renovate  
Renovate reads `renovate.json` automatically once installed.

> [!IMPORTANT]
> The `auto-merge.yml` workflow depends on Renovate being installed. Without it, patch PRs will not be created and auto-merge will never trigger.

---

## 📦 What Gets Installed

### GitHub Actions Workflows

| File | Purpose |
|------|---------|
| `ci.yml` | Build, test, lint — triggered on push/PR |
| `security-scan.yml` | Semgrep SAST + TruffleHog secrets + Trivy container |
| `auto-fix.yml` | Auto-PR to fix Prettier + ESLint on CI failure |
| `auto-merge.yml` | Auto-merge Renovate patch PRs after CI passes |

> [!TIP]
> All four workflows are independent. You can adopt them incrementally — start with `ci.yml` only, then add the others as your team grows.

### Dependency Management

`renovate.json` is configured with:
- **Patch** updates → auto-merge after CI passes
- **Minor** updates → grouped weekly PR, manual review
- **Major** updates → individual PR, mandatory review

### Pre-Push Hooks

Blocks `git push` if any of the following fail:
- Prettier format check
- ESLint (zero warnings tolerance)
- TypeScript typecheck (`tsc --noEmit`)

> [!NOTE]
> Hooks are skip-aware — if no Prettier config, ESLint config, or `tsconfig.json` is found in the project root, that check is silently skipped rather than erroring.

---

## ⚙️ Script Reference

### `generate.ps1` — Initialize a new project

```powershell
.\scripts\generate.ps1 -target ../my-repo
.\scripts\generate.ps1 -target ../my-repo -stack NEXTJS   # override detection
.\scripts\generate.ps1 -target ../my-repo -force          # overwrite existing files
```

### `sync.ps1` — Update workflow files in an existing project

```powershell
.\scripts\sync.ps1 -target ../my-repo          # skip files with no changes
.\scripts\sync.ps1 -target ../my-repo -force   # overwrite all
```

### `validate.ps1` — Verify the setup is correct

```powershell
.\scripts\validate.ps1                         # check current directory
.\scripts\validate.ps1 -target ../my-repo
```

### `detect-stack.ps1` — Detect stack type only

```powershell
.\scripts\detect-stack.ps1                     # detect in current directory
.\scripts\detect-stack.ps1 -path ../my-repo    # detect in specific path
# Output: TURBOREPO | NEXTJS | NESTJS | NODE
```

---

## 🔍 Stack Detection Logic

| Priority | File Detected | Stack |
|----------|--------------|-------|
| 1 | `turbo.json` | `TURBOREPO` |
| 2 | `next.config.js` / `.ts` / `.mjs` | `NEXTJS` |
| 3 | `nest-cli.json` | `NESTJS` |
| 4 | *(none of the above)* | `NODE` |

> [!NOTE]
> Turborepo is checked first because a monorepo may contain a Next.js app internally. Checking `turbo.json` first prevents misclassification.

---

## 🛠️ Customizing Per-repo

After running `generate.ps1`, these files are yours to edit:
- **`ci.yml`** — add project-specific jobs (DB migration, health checks, gatekeeper)
- **`renovate.json`** — add `packageRules` for internal org packages
- **`.git/hooks/pre-push`** — add project-specific checks

To pull template updates without overwriting your customizations:

```powershell
.\scripts\sync.ps1 -target ../my-repo
```

> [!TIP]
> `sync.ps1` compares file checksums before overwriting. Files you've modified will be skipped unless you pass `-force`.

---

## 📋 Stack-Specific Notes

### Turborepo

- Set `TURBO_TOKEN` and `TURBO_TEAM` secrets for remote caching
- `pnpm/action-setup@v4` reads the pnpm version from `packageManager` in `package.json` — do not pin the version manually in the workflow
- The `HEAD^1` filter is applied automatically — only changed packages are built and tested

### NestJS

- If Prisma is used: add `prisma generate` before the build step in `ci.yml`
- PHI/PII fields must use the `@Exclude()` decorator — enforced by linter rules

### Next.js

- Build output (`.next/`) is already included in the upload-artifact path
- `NEXT_PUBLIC_*` environment variables go in GitHub Actions **vars**, not secrets

---

## 🆘 Troubleshooting

**Auto-fix does not trigger after CI fails?**  
Ensure the workflow name in `auto-fix.yml` exactly matches `name:` in `ci.yml`. This comparison is case-sensitive.

```yaml
# auto-fix.yml
workflows: ['CI']   # must match exactly
```

**Container scan always skips?**  
Expected behavior — the job only runs when a `Dockerfile` is present in the repository (`hashFiles('**/Dockerfile') != ''`).

**Pre-push hook does not run on Windows?**

```bash
git config core.hooksPath .git/hooks
```

**Renovate is installed but creates no PRs?**  
Check that Renovate has repository access: GitHub → Settings → GitHub Apps → Renovate → Repository access.

**`generate.ps1` reports "path not found"?**  
Run the script from the `claudesy-devkit/` root directory, not from inside `scripts/`.

> [!WARNING]
> Do not run `generate.ps1 -force` on a repository with existing workflow customizations unless you intend to overwrite them. Use `sync.ps1` instead for safe updates.

---

## 📄 Source

Extracted from `abyss-monorepo` (Claudesy organization).  
Maintained by Dr. Ferdi Iskandar (CEO, Sentra Artificial Intelligence).

**Last updated:** 2026-04-15

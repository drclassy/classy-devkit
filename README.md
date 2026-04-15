# claudesy-devkit

Git workflow scaffold untuk semua Claudesy organization projects.

**Deskripsi:** Setiap repo baru di Claudesy butuh CI, security scan, dependency automation, dan pre-push hooks yang identik — tapi setup manual tiap repo itu mahal dan inconsistent. `claudesy-devkit` solve ini dengan satu command: auto-detect stack, copy semua template files, install hooks. Diekstrak dari proven automation stack di `abyss-monorepo`.  
**Prinsip:** Deterministic tools, minimum agents, maximum coverage. Bukan Artificial Intelligence untuk routine CI — hanya ketika benar-benar butuh judgment.

---

## 🚀 Quickstart (5 menit)

### 1. Clone Repo

```powershell
git clone https://github.com/Docsynapse/claudesy-devkit.git
cd claudesy-devkit
```

### 2. Setup Awal

```powershell
.\scripts\generate.ps1 -target ../nama-repo-baru
```

Script ini akan:
- Auto-detect stack (Turborepo / Next.js / NestJS / Node)
- Copy semua workflow files ke `.github/workflows/` + `renovate.json`
- Install pre-push hooks (format + lint + typecheck)

### 3. Push & Lihat CI

```bash
cd ../nama-repo-baru
git add .github/ renovate.json
git commit -m "chore: add claudesy-devkit CI scaffold"
git push
```

### 4. Setup Secrets (disarankan)

| Secret | Fungsi | Required? |
|--------|--------|-----------|
| `SEMGREP_APP_TOKEN` | Semgrep dashboard & PR comments | Optional |
| `SNYK_TOKEN` | Snyk vulnerability scan | Optional |
| `TURBO_TOKEN` | Turborepo remote cache | Turborepo only |
| `TURBO_TEAM` | Turborepo team identifier | Turborepo only |

**Cara set:** GitHub → Settings → Secrets and variables → Actions

### 5. Enable Renovate (dependency auto-update)

Install app: https://github.com/apps/renovate  
Renovate baca `renovate.json` otomatis.

---

## 📦 Apa Yang Di-install

### GitHub Actions Workflows

| File | Fungsi |
|------|--------|
| `ci.yml` | Build, test, lint — push/PR |
| `security-scan.yml` | Semgrep SAST + TruffleHog secrets + Trivy container |
| `auto-fix.yml` | Auto-PR fix Prettier + ESLint saat CI gagal |
| `auto-merge.yml` | Auto-merge Renovate patch PRs setelah CI pass |

### Dependency Management

`renovate.json`:
- **Patch:** auto-merge setelah CI pass
- **Minor:** grouped PR mingguan, manual review
- **Major:** PR individual, wajib review Boss

### Pre-Push Hooks

Block push jika:
- Prettier format error
- ESLint error
- TypeScript type error

---

## ⚙️ Script Reference

### `generate.ps1` — Setup project baru

```powershell
.\scripts\generate.ps1 -target ../my-repo
.\scripts\generate.ps1 -target ../my-repo -stack NEXTJS   # override detection
.\scripts\generate.ps1 -target ../my-repo -force          # overwrite existing files
```

### `sync.ps1` — Update workflow files di existing project

```powershell
.\scripts\sync.ps1 -target ../my-repo          # skip files yang tidak berubah
.\scripts\sync.ps1 -target ../my-repo -force   # overwrite semua
```

### `validate.ps1` — Cek apakah setup sudah benar

```powershell
.\scripts\validate.ps1                         # cek current directory
.\scripts\validate.ps1 -target ../my-repo
```

### `detect-stack.ps1` — Deteksi stack type saja

```powershell
.\scripts\detect-stack.ps1                     # detect di current dir
.\scripts\detect-stack.ps1 -path ../my-repo    # detect di path tertentu
# Output: TURBOREPO | NEXTJS | NESTJS | NODE
```

---

## 🔍 Stack Detection Logic

| Priority | File | Stack |
|----------|------|-------|
| 1 | `turbo.json` | `TURBOREPO` |
| 2 | `next.config.js` / `.ts` / `.mjs` | `NEXTJS` |
| 3 | `nest-cli.json` | `NESTJS` |
| 4 | — | `NODE` |

Turborepo dicek pertama karena monorepo bisa contain Next.js di dalamnya.

---

## 🛠️ Customizing Per-repo

Edit setelah generate:
- **`ci.yml`**: tambah jobs custom (DB migrate, healthcheck, gatekeeper)
- **`renovate.json`**: tambah `packageRules` untuk package internal org
- **Pre-push hook**: tambah checks project-specific

Update template tanpa overwrite customisasi: `.\scripts\sync.ps1 -target ../repo`

---

## 📋 Stack-Specific Notes

### Turborepo

- Set `TURBO_TOKEN` & `TURBO_TEAM` secrets untuk remote caching
- `pnpm/action-setup@v4` baca versi dari `packageManager` di `package.json` — jangan pin versi manual di workflow
- HEAD^1 filter otomatis applied — hanya build/test packages yang berubah

### NestJS

- Ada Prisma? Tambah `prisma generate` sebelum build step di `ci.yml`
- PHI/PII fields wajib `@Exclude()` decorator

### Next.js

- Build output `.next/` sudah included di upload-artifact path
- `NEXT_PUBLIC_*` env vars → GitHub Actions **vars** (bukan secrets)

---

## 🆘 Troubleshooting

**Auto-fix ga trigger setelah CI gagal?**  
Pastikan `workflows: ['CI']` di `auto-fix.yml` cocok persis dengan `name:` di `ci.yml`. Case-sensitive.

**Container scan selalu skip?**  
Normal — job hanya jalan kalau ada `Dockerfile` di repo (`hashFiles('**/Dockerfile') != ''`).

**Pre-push hook ga jalan di Windows?**
```bash
git config core.hooksPath .git/hooks
```

**Renovate tidak buat PR?**  
Cek apakah Renovate app sudah di-install di repo: GitHub → Settings → GitHub Apps.

**`generate.ps1` error "path not found"?**  
Jalankan dari root `claudesy-devkit/`, bukan dari dalam `scripts/`.

---

## 📄 Source

Diekstrak dari `abyss-monorepo` (Claudesy organization).  
Maintained oleh Dr. Ferdi Iskandar (CEO Sentra Artificial Intelligence).

**Last updated:** 2026-04-15

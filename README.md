# claudesy-devkit

Git workflow scaffold for all Claudesy organization projects.
Extracted from the proven automation stack in `abyss-monorepo`.

**Prinsip:** Deterministic tools, bukan Artificial Intelligence untuk routine CI.
Minimum agents, maximum coverage.

---

## Quickstart (5 menit)

### 1. Clone devkit

```powershell
git clone https://github.com/Claudesy/claudesy-devkit.git
cd claudesy-devkit
```

### 2. Run generate ke project baru

```powershell
.\scripts\generate.ps1 -target ../my-new-repo
```

Script ini akan:
- Auto-detect stack (Turborepo / Next.js / NestJS / Node)
- Copy semua workflow files ke `.github/workflows/`
- Copy `renovate.json`
- Install pre-push hooks (format + lint + typecheck)

### 3. Push dan lihat CI berjalan

```bash
cd ../my-new-repo
git add .github/ renovate.json
git commit -m "chore: add claudesy-devkit CI scaffold"
git push
```

### 4. Setup secrets (optional tapi disarankan)

| Secret | Fungsi | Required? |
|--------|--------|-----------|
| `SEMGREP_APP_TOKEN` | Semgrep dashboard & PR comments | Optional |
| `SNYK_TOKEN` | Snyk vulnerability database | Optional |
| `TURBO_TOKEN` | Turborepo remote cache | Only for Turborepo repos |
| `TURBO_TEAM` | Turborepo team identifier | Only for Turborepo repos |

Tambahkan di: GitHub repo → Settings → Secrets and variables → Actions

### 5. Enable Renovate

Install Renovate GitHub App: https://github.com/apps/renovate

Setelah install, Renovate akan baca `renovate.json` secara otomatis.

---

## Apa yang di-install

### GitHub Actions Workflows

| File | Fungsi |
|------|--------|
| `ci.yml` | Build, test, lint — triggered on push/PR |
| `security-scan.yml` | Semgrep SAST + TruffleHog secrets + Trivy container |
| `auto-fix.yml` | Auto-PR ketika CI gagal — fix Prettier + ESLint |
| `auto-merge.yml` | Auto-merge Renovate patch PRs setelah CI pass |

### Dependency Management

`renovate.json` dikonfigurasi dengan:
- **Patch** updates → auto-merge (setelah CI pass)
- **Minor** updates → grouped PR mingguan (manual review)
- **Major** updates → PR individual, perlu review Boss

### Pre-Push Hooks

Dijalankan sebelum setiap `git push`. Blocks push kalau ada:
- Prettier format error
- ESLint error
- TypeScript type error

---

## Script Reference

### `generate.ps1` — Setup project baru

```powershell
.\scripts\generate.ps1 -target ../my-repo
.\scripts\generate.ps1 -target ../my-repo -stack NEXTJS   # override detection
.\scripts\generate.ps1 -target ../my-repo -force          # overwrite existing files
```

### `sync.ps1` — Update workflow files di existing project

```powershell
.\scripts\sync.ps1 -target ../my-repo         # skip unchanged files
.\scripts\sync.ps1 -target ../my-repo -force  # overwrite all
```

### `validate.ps1` — Cek apakah setup sudah benar

```powershell
.\scripts\validate.ps1                    # cek current directory
.\scripts\validate.ps1 -target ../my-repo
```

### `detect-stack.ps1` — Deteksi stack type

```powershell
.\scripts\detect-stack.ps1
.\scripts\detect-stack.ps1 -path ../my-repo
# Output: TURBOREPO | NEXTJS | NESTJS | NODE
```

---

## Stack Detection Logic

| File ditemukan | Stack terdeteksi |
|----------------|-----------------|
| `turbo.json` | `TURBOREPO` |
| `next.config.js` / `.ts` / `.mjs` | `NEXTJS` |
| `nest-cli.json` | `NESTJS` |
| (tidak ada di atas) | `NODE` |

Turborepo dicek pertama karena monorepo bisa contain Next.js di dalamnya.

---

## Customizing per-repo

Setelah generate, kamu bisa edit files yang di-copy:

- **`ci.yml`** — tambah jobs project-specific (health check, DB migration, dll)
- **`renovate.json`** — tambah `packageRules` untuk package internal org
- **`.git/hooks/pre-push`** — tambah checks project-specific

Untuk pull update dari template tanpa overwrite customizations:

```powershell
.\scripts\sync.ps1 -target ../my-repo  # hanya update files yang belum diubah
```

---

## Stack-Specific Notes

### Turborepo

- Set `TURBO_TOKEN` dan `TURBO_TEAM` secrets untuk remote caching
- `pnpm/action-setup@v4` membaca versi dari `packageManager` di `package.json` — jangan pin versi manual
- HEAD^1 filter otomatis applied — hanya build/test packages yang berubah

### NestJS

- Kalau ada Prisma: tambahkan `prisma generate` sebelum build step di `ci.yml`
- PHI/PII fields wajib `@Exclude()` decorator

### Next.js

- Build output `.next/` sudah di-include di upload-artifact path
- `NEXT_PUBLIC_*` env vars masuk sebagai GitHub Actions vars (bukan secrets)

---

## Troubleshooting

**Auto-fix tidak trigger setelah CI gagal?**

Pastikan nama workflow di `auto-fix.yml` cocok dengan nama CI workflow kamu:
```yaml
workflows: ['CI']  # harus sama persis dengan name: di ci.yml
```

**Container scan skip terus?**

Normal — container scan hanya jalan kalau ada `Dockerfile` di repo.

**Pre-push hook tidak jalan di Windows?**

Pastikan Git for Windows dikonfigurasi untuk run shell scripts:
```bash
git config core.hooksPath .git/hooks
```

---

## Source

Diekstrak dari `abyss-monorepo` (Claudesy organization).
Maintained oleh Dr. Ferdi Iskandar (Claudesy).

# audit.ps1 — 本機 CI 流程，提交前執行確保品質
# 不被 chezmoi 部署（見 .chezmoiignore）

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$failed = $false

Write-Host "========== Audit ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. PowerShell syntax
# ------------------------------------------------------------
Write-Host "[1/4] PowerShell syntax..." -ForegroundColor Yellow
Get-ChildItem "$root\*.ps1" | Where-Object { $_.Name -ne "audit.ps1" } | ForEach-Object {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$errors) | Out-Null
    if ($errors) {
        Write-Host "  [error] $($_.Name)" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "    line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red }
        $failed = $true
    } else {
        Write-Host "  [ok] $($_.Name)" -ForegroundColor DarkGray
    }
}
Write-Host ""

# ------------------------------------------------------------
# 2. Markdown lint
# ------------------------------------------------------------
Write-Host "[2/4] Markdown lint..." -ForegroundColor Yellow
Push-Location $root
npx --yes markdownlint-cli "**/*.md" --ignore node_modules 2>&1 | ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) {
    $failed = $true
} else {
    Write-Host "  [ok] all markdown files" -ForegroundColor DarkGray
}
Pop-Location
Write-Host ""

# ------------------------------------------------------------
# 3. chezmoi dry-run
# ------------------------------------------------------------
Write-Host "[3/4] chezmoi dry-run..." -ForegroundColor Yellow
chezmoi -S $root apply --dry-run --verbose 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [error] chezmoi dry-run failed" -ForegroundColor Red
    $failed = $true
} else {
    Write-Host "  [ok] chezmoi dry-run passed" -ForegroundColor DarkGray
}
Write-Host ""

# ------------------------------------------------------------
# 4. Consistency checks
# ------------------------------------------------------------
Write-Host "[4/4] Consistency checks..." -ForegroundColor Yellow
$consistencyFailed = $false

# 4a. README 工具表 vs 實際 run_*.ps1 檔案
$scriptFiles   = (Get-ChildItem "$root\run_*.ps1").Name
$readmeContent = Get-Content "$root\README.md" -Raw
$readmeScripts = [regex]::Matches($readmeContent, '`(run_\w+\.ps1)`') |
    ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

foreach ($f in $scriptFiles) {
    if ($f -notin $readmeScripts) {
        Write-Host "  [warn] $f exists but not listed in README.md" -ForegroundColor Yellow
        $consistencyFailed = $true
    }
}
foreach ($r in $readmeScripts) {
    if ($r -notin $scriptFiles) {
        Write-Host "  [warn] README.md lists $r but file not found" -ForegroundColor Yellow
        $consistencyFailed = $true
    }
}

# 4b. winget 腳本是否都有前置檢查
Get-ChildItem "$root\run_*.ps1" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if (($content -match 'winget install') -and (-not ($content -match 'Get-Command winget'))) {
        Write-Host "  [warn] $($_.Name): uses winget but missing Get-Command winget check" -ForegroundColor Yellow
        $consistencyFailed = $true
    }
}

# 4c. npm 腳本是否包含完整 Node.js 前置區段
Get-ChildItem "$root\run_*.ps1" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match 'npm install -g') {
        if (-not ($content -match 'Get-Command npm')) {
            Write-Host "  [warn] $($_.Name): uses npm but missing Get-Command npm check" -ForegroundColor Yellow
            $consistencyFailed = $true
        }
        if (-not ($content -match 'OpenJS\.NodeJS\.LTS')) {
            Write-Host "  [warn] $($_.Name): uses npm but missing Node.js fallback install" -ForegroundColor Yellow
            $consistencyFailed = $true
        }
    }
}

if ($consistencyFailed) {
    $failed = $true
} else {
    Write-Host "  [ok] README sync, winget checks, npm bootstrap" -ForegroundColor DarkGray
}
Write-Host ""

# ------------------------------------------------------------
# Result
# ------------------------------------------------------------
if ($failed) {
    Write-Host "========== FAILED — fix errors before committing ==========" -ForegroundColor Red
    exit 1
} else {
    Write-Host "========== All checks passed ==========" -ForegroundColor Green
}
Write-Host ""

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
Write-Host "[1/3] PowerShell syntax..." -ForegroundColor Yellow
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
Write-Host "[2/3] Markdown lint..." -ForegroundColor Yellow
Push-Location $root
npx markdownlint-cli "**/*.md" --ignore node_modules 2>&1 | ForEach-Object { Write-Host "  $_" }
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
Write-Host "[3/3] chezmoi dry-run..." -ForegroundColor Yellow
chezmoi -S $root apply --dry-run --verbose 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [error] chezmoi dry-run failed" -ForegroundColor Red
    $failed = $true
} else {
    Write-Host "  [ok] chezmoi dry-run passed" -ForegroundColor DarkGray
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

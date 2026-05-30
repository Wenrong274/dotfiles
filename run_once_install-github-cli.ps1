# run_once_install-github-cli.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝 GitHub CLI（gh）

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: GitHub CLI ==========" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[error] winget not found." -ForegroundColor Red
    Write-Host "        Install 'App Installer' from Microsoft Store, then re-run." -ForegroundColor DarkGray
    Write-Host "        https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor DarkGray
    exit 1
}

# ------------------------------------------------------------
# GitHub CLI
# ------------------------------------------------------------
winget list --id GitHub.cli --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] GitHub CLI already installed" -ForegroundColor DarkGray
} else {
    Write-Host "  Installing GitHub CLI..." -ForegroundColor Green
    winget install --id GitHub.cli --exact --source winget `
        --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [error] GitHub CLI install failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    Write-Host "  GitHub CLI installed" -ForegroundColor Green
}
Write-Host ""

# ------------------------------------------------------------
# 警告彙整
# ------------------------------------------------------------
if ($warnings.Count -gt 0) {
    Write-Host "========== 警告 ==========" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  !! $w" -ForegroundColor Yellow }
    Write-Host ""
}

Write-Host "========== GitHub CLI Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""

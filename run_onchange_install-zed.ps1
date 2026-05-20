# run_onchange_install-zed.ps1
# chezmoi 在新機器首次 apply，或此腳本內容變更時自動執行
# run_onchange（而非 run_once）：日後若調整安裝邏輯，chezmoi 會重跑
# 設定檔（settings.json）由 chezmoi 管理，不在此腳本處理

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Zed ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 前置檢查
# ------------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[error] winget not found." -ForegroundColor Red
    Write-Host "        Install 'App Installer' from Microsoft Store, then re-run." -ForegroundColor DarkGray
    Write-Host "        https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor DarkGray
    exit 1
}

# ------------------------------------------------------------
# 1. 安裝 Zed
# ------------------------------------------------------------
Write-Host "[1/1] Installing Zed..." -ForegroundColor Yellow

winget list --id ZedIndustries.Zed --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] Zed already installed" -ForegroundColor DarkGray
} else {
    Write-Host "  Installing Zed..." -ForegroundColor Green
    winget install --id ZedIndustries.Zed --exact --source winget `
        --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [error] winget install Zed failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
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

Write-Host "========== Zed Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "Paths:" -ForegroundColor Yellow
Write-Host "  Config:  $env:APPDATA\Zed\settings.json  (managed by chezmoi)" -ForegroundColor DarkGray
Write-Host "  Keymap:  $env:APPDATA\Zed\keymap.json    (managed by chezmoi)" -ForegroundColor DarkGray
Write-Host "  Token:   GitHub token 由 chezmoi template 自動填入" -ForegroundColor DarkGray
Write-Host ""

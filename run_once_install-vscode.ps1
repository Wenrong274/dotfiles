# run_once_install-vscode.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝 Visual Studio Code
# 設定檔由 VSCode Settings Sync 自動還原，不在此腳本處理

$ErrorActionPreference = "Stop"

Write-Host "========== Bootstrap: VSCode ==========" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[error] winget not found." -ForegroundColor Red
    exit 1
}

winget list --id Microsoft.VisualStudioCode --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] VSCode already installed" -ForegroundColor DarkGray
} else {
    Write-Host "  Installing VSCode..." -ForegroundColor Green
    winget install --id Microsoft.VisualStudioCode --exact --source winget `
        --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [error] winget install VSCode failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    Write-Host "  VSCode installed" -ForegroundColor Green
}
Write-Host ""

Write-Host "========== VSCode Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "  登入 Settings Sync 後設定檔自動還原" -ForegroundColor DarkGray
Write-Host ""

# run_once_install-chocolatey.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝 Chocolatey 套件管理器
# 注意：需要系統管理員權限

$ErrorActionPreference = "Stop"

Write-Host "========== Bootstrap: Chocolatey ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 前置檢查
# ------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "  [error] 需要系統管理員權限" -ForegroundColor Red
    Write-Host "          請以系統管理員身分重新執行: chezmoi apply" -ForegroundColor DarkGray
    exit 1
}

# 已安裝則跳過
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "  [skip] Chocolatey already installed ($(choco --version))" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "========== Chocolatey Bootstrap Complete ==========" -ForegroundColor Cyan
    exit 0
}

# ------------------------------------------------------------
# 安裝 Chocolatey（官方安裝腳本）
# ------------------------------------------------------------
Write-Host "  Installing Chocolatey..." -ForegroundColor Green

Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = `
    [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
    'https://community.chocolatey.org/install.ps1'))

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    # PATH 尚未刷新，從預設路徑確認
    $chocoExe = "$env:ProgramData\chocolatey\bin\choco.exe"
    if (-not (Test-Path $chocoExe)) {
        Write-Host "  [error] Chocolatey 安裝失敗" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "========== Chocolatey Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "  choco: $env:ProgramData\chocolatey\bin\choco.exe" -ForegroundColor DarkGray
Write-Host "  重新開啟 shell 後 choco 指令即可使用" -ForegroundColor DarkGray
Write-Host ""

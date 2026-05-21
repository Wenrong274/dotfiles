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

# 已安裝則跳過 Chocolatey 安裝步驟
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "  [skip] Chocolatey already installed ($(choco --version))" -ForegroundColor DarkGray
} else {

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
    # 刷新 PATH 讓後續 choco 指令可用
    $env:Path = "$env:ProgramData\chocolatey\bin;" + $env:Path
}

} # end if choco not installed

# ------------------------------------------------------------
# 安裝開發套件
# ------------------------------------------------------------
Write-Host ""
Write-Host "========== Installing Packages ==========" -ForegroundColor Cyan
Write-Host ""

$packages = @(
    @{ id = "ripgrep"; name = "ripgrep (rg)" },
    @{ id = "bat";     name = "bat" }
)

$warnings = [System.Collections.Generic.List[string]]::new()

foreach ($pkg in $packages) {
    $installed = choco list --local-only --exact $pkg.id 2>$null | Select-String $pkg.id
    if ($installed) {
        Write-Host "  [skip] $($pkg.name) already installed" -ForegroundColor DarkGray
    } else {
        Write-Host "  Installing $($pkg.name)..." -ForegroundColor Green
        choco install $pkg.id -y --no-progress
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [warn] $($pkg.name) install failed (exit $LASTEXITCODE)" -ForegroundColor Yellow
            $warnings.Add("$($pkg.name) 安裝失敗 — 請手動執行: choco install $($pkg.id)")
        }
    }
}

# ------------------------------------------------------------
# 警告彙整
# ------------------------------------------------------------
if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "========== 警告 ==========" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  !! $w" -ForegroundColor Yellow }
}

Write-Host ""
Write-Host "========== Chocolatey Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "  choco: $env:ProgramData\chocolatey\bin\choco.exe" -ForegroundColor DarkGray
Write-Host "  重新開啟 shell 後指令即可使用" -ForegroundColor DarkGray
Write-Host ""

# bootstrap.ps1 — 新機器一鍵設定 Neovim 環境
# Usage: git clone https://github.com/Wenrong274/dotfiles ~/dotfiles
#        cd ~/dotfiles && .\bootstrap.ps1
#
# 前提：Windows 10/11 + winget 可用
# VSCode 設定由 Settings Sync 自動還原，不在此腳本範圍內

$ErrorActionPreference = "Stop"

Write-Host "========== Bootstrap: Neovim ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. 安裝核心軟體（winget）
# ------------------------------------------------------------
Write-Host "[1/3] Installing software via winget..." -ForegroundColor Yellow

$packages = @(
    @{ id = "Neovim.Neovim";        name = "Neovim" },
    @{ id = "Microsoft.PowerShell"; name = "PowerShell 7" }
)

foreach ($pkg in $packages) {
    $installed = winget list --id $pkg.id 2>$null | Select-String $pkg.id
    if ($installed) {
        Write-Host "  [skip] $($pkg.name) already installed" -ForegroundColor DarkGray
    } else {
        Write-Host "  Installing $($pkg.name)..." -ForegroundColor Green
        winget install --id $pkg.id --accept-source-agreements --accept-package-agreements
    }
}
Write-Host ""

# ------------------------------------------------------------
# 2. 下載 im-select.exe（IME 自動切換）
# ------------------------------------------------------------
Write-Host "[2/3] Setting up im-select.exe..." -ForegroundColor Yellow

$toolsDir = Join-Path $env:USERPROFILE "tools"
$imSelectPath = Join-Path $toolsDir "im-select.exe"

if (Test-Path $imSelectPath) {
    Write-Host "  [skip] im-select.exe already exists" -ForegroundColor DarkGray
} else {
    New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
    $url = "https://github.com/daipeihust/im-select/raw/master/win/out/x64/im-select.exe"
    Write-Host "  Downloading im-select.exe..." -ForegroundColor Green
    try {
        Invoke-WebRequest -Uri $url -OutFile $imSelectPath -UseBasicParsing
        Write-Host "  Saved to: $imSelectPath" -ForegroundColor Green
    } catch {
        Write-Host "  [warn] Download failed. Please download manually:" -ForegroundColor Red
        Write-Host "         $url" -ForegroundColor DarkGray
        Write-Host "         Save to: $imSelectPath" -ForegroundColor DarkGray
    }
}
Write-Host ""

# ------------------------------------------------------------
# 3. 套用 Neovim 設定
# ------------------------------------------------------------
Write-Host "[3/3] Installing Neovim config..." -ForegroundColor Yellow

$nvimDst = Join-Path $env:LOCALAPPDATA "nvim"
$nvimSrc = Join-Path $PSScriptRoot "nvim\init.lua"

if (-not (Test-Path $nvimSrc)) {
    Write-Host "  [error] nvim/init.lua not found in repo" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $nvimDst)) {
    New-Item -ItemType Directory -Path $nvimDst -Force | Out-Null
}

$dstFile = Join-Path $nvimDst "init.lua"
if (Test-Path $dstFile) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $dstFile "$dstFile.$timestamp.bak"
    Write-Host "  Backed up existing init.lua" -ForegroundColor Yellow
}

Copy-Item $nvimSrc -Destination $dstFile -Force
Write-Host "  Installed: init.lua -> $nvimDst" -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
Write-Host "========== Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Reload VSCode -> sign in to Settings Sync to restore VSCode profiles" -ForegroundColor DarkGray
Write-Host "  2. First Neovim launch may take ~5s (lazy.nvim installs plugins)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "  - Neovim path:   C:\Program Files\Neovim\bin\nvim.exe" -ForegroundColor DarkGray
Write-Host "  - im-select:     $env:USERPROFILE\tools\im-select.exe" -ForegroundColor DarkGray
Write-Host "  - Neovim config: $env:LOCALAPPDATA\nvim\init.lua" -ForegroundColor DarkGray
Write-Host ""

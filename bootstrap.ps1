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
# 0. 前置檢查
# ------------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[error] winget not found." -ForegroundColor Red
    Write-Host "        Install 'App Installer' from Microsoft Store, then re-run." -ForegroundColor DarkGray
    Write-Host "        https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor DarkGray
    exit 1
}

# ------------------------------------------------------------
# 1. 安裝核心軟體（winget）
# ------------------------------------------------------------
Write-Host "[1/4] Installing software via winget..." -ForegroundColor Yellow

$packages = @(
    @{ id = "Neovim.Neovim";        name = "Neovim" },
    @{ id = "Microsoft.PowerShell"; name = "PowerShell 7" }
)

foreach ($pkg in $packages) {
    # --exact 避免模糊比對, 用 LASTEXITCODE 判斷 (winget 找不到時回傳非 0)
    winget list --id $pkg.id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [skip] $($pkg.name) already installed" -ForegroundColor DarkGray
    } else {
        Write-Host "  Installing $($pkg.name)..." -ForegroundColor Green
        winget install --id $pkg.id --exact --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [warn] winget install exited with $LASTEXITCODE" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# ------------------------------------------------------------
# 2. 下載 im-select.exe（IME 自動切換）
#    pin 到固定 commit + SHA256 校驗 (供應鏈安全 / 可重現)
# ------------------------------------------------------------
Write-Host "[2/4] Setting up im-select.exe..." -ForegroundColor Yellow

$toolsDir = Join-Path $env:USERPROFILE "tools"
$imSelectPath = Join-Path $toolsDir "im-select.exe"

# 鎖定到此 commit (2023-04-19, exe 最後一次更新)
$imSelectCommit = "11ed9277fb3118b63b36cfca57c39fa4cc882512"
$imSelectSha256 = "E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6"
$imSelectUrl = "https://raw.githubusercontent.com/daipeihust/im-select/$imSelectCommit/win/out/x64/im-select.exe"

function Test-ImSelectHash {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash -eq $imSelectSha256
}

if (Test-ImSelectHash -Path $imSelectPath) {
    Write-Host "  [skip] im-select.exe already present and hash matches" -ForegroundColor DarkGray
} else {
    if (Test-Path $imSelectPath) {
        Write-Host "  [warn] existing im-select.exe has different hash, replacing" -ForegroundColor Yellow
    }
    New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
    Write-Host "  Downloading im-select.exe (pinned commit $($imSelectCommit.Substring(0,7)))..." -ForegroundColor Green
    $tmpPath = "$imSelectPath.download"
    try {
        Invoke-WebRequest -Uri $imSelectUrl -OutFile $tmpPath -UseBasicParsing
        $actual = (Get-FileHash -Path $tmpPath -Algorithm SHA256).Hash
        if ($actual -ne $imSelectSha256) {
            Remove-Item $tmpPath -Force
            Write-Host "  [error] SHA256 mismatch — refusing to install" -ForegroundColor Red
            Write-Host "          expected: $imSelectSha256" -ForegroundColor DarkGray
            Write-Host "          actual:   $actual" -ForegroundColor DarkGray
            exit 1
        }
        Move-Item -Path $tmpPath -Destination $imSelectPath -Force
        Write-Host "  Saved to: $imSelectPath (SHA256 verified)" -ForegroundColor Green
    } catch {
        if (Test-Path $tmpPath) { Remove-Item $tmpPath -Force }
        Write-Host "  [warn] Download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "         Manual: $imSelectUrl" -ForegroundColor DarkGray
        Write-Host "         Save to: $imSelectPath" -ForegroundColor DarkGray
    }
}
Write-Host ""

# ------------------------------------------------------------
# 3. 套用 Neovim 設定 (idempotent: 內容相同則跳過, 不同才備份+覆蓋)
# ------------------------------------------------------------
Write-Host "[3/4] Installing Neovim config..." -ForegroundColor Yellow

$nvimDst = Join-Path $env:LOCALAPPDATA "nvim"
$nvimSrcDir = Join-Path $PSScriptRoot "nvim"
$nvimSrc = Join-Path $nvimSrcDir "init.lua"
$lockSrc = Join-Path $nvimSrcDir "lazy-lock.json"

if (-not (Test-Path $nvimSrc)) {
    Write-Host "  [error] nvim/init.lua not found in repo" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $nvimDst)) {
    New-Item -ItemType Directory -Path $nvimDst -Force | Out-Null
}

function Sync-ConfigFile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Label
    )
    if (Test-Path $Destination) {
        $srcHash = (Get-FileHash -Path $Source -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -Path $Destination -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) {
            Write-Host "  [skip] $Label unchanged" -ForegroundColor DarkGray
            return
        }
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item $Destination "$Destination.$timestamp.bak"
        Write-Host "  Backed up existing $Label" -ForegroundColor Yellow
    }
    Copy-Item $Source -Destination $Destination -Force
    Write-Host "  Installed: $Label -> $(Split-Path $Destination -Parent)" -ForegroundColor Green
}

Sync-ConfigFile -Source $nvimSrc -Destination (Join-Path $nvimDst "init.lua") -Label "init.lua"

# 同步 lazy-lock.json (固定 plugin 版本)
if (Test-Path $lockSrc) {
    Sync-ConfigFile -Source $lockSrc -Destination (Join-Path $nvimDst "lazy-lock.json") -Label "lazy-lock.json"
}
Write-Host ""

# ------------------------------------------------------------
# 4. 首次安裝 plugin 並 restore 到 lock 版本
#    headless 跑一次, 使用者開 nvim 不必再手動 :Lazy restore
# ------------------------------------------------------------
Write-Host "[4/4] Installing & restoring plugins..." -ForegroundColor Yellow

# winget 裝完當下 PATH 可能還沒刷新, fallback 到預設安裝路徑
$nvimExe = (Get-Command nvim -ErrorAction SilentlyContinue).Source
if (-not $nvimExe) {
    $defaultPath = "C:\Program Files\Neovim\bin\nvim.exe"
    if (Test-Path $defaultPath) { $nvimExe = $defaultPath }
}

if ($nvimExe) {
    Write-Host "  Running: $nvimExe --headless +Lazy! restore +qa" -ForegroundColor Green
    & $nvimExe --headless "+Lazy! restore" "+qa" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Plugins restored to locked commits" -ForegroundColor Green
    } else {
        Write-Host "  [warn] :Lazy restore exited with $LASTEXITCODE — open nvim to inspect" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [skip] nvim not found on PATH or default location" -ForegroundColor DarkGray
    Write-Host "         Open a new shell and run: nvim --headless +Lazy! restore +qa" -ForegroundColor DarkGray
}
Write-Host ""

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
Write-Host "========== Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Reload VSCode -> sign in to Settings Sync to restore VSCode profiles" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "  - Neovim path:   C:\Program Files\Neovim\bin\nvim.exe" -ForegroundColor DarkGray
Write-Host "  - im-select:     $env:USERPROFILE\tools\im-select.exe" -ForegroundColor DarkGray
Write-Host "  - Neovim config: $env:LOCALAPPDATA\nvim\init.lua" -ForegroundColor DarkGray
Write-Host ""

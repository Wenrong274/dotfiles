# install.ps1 — 新機器一鍵設定 Zed 環境
# Usage: .\install.ps1
#        .\install.ps1 -DryRun   # 預覽，不實際執行
#
# 前提：Windows 10/11 + winget 可用

param(
    [switch]$DryRun  # 只顯示動作，不實際寫入檔案或安裝軟體
)

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Zed ==========" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY-RUN] 預覽模式，不會實際修改任何東西`n" -ForegroundColor Magenta }
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
# 1. 安裝 Zed（winget）
# ------------------------------------------------------------
Write-Host "[1/2] Installing Zed..." -ForegroundColor Yellow

winget list --id ZedIndustries.Zed --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] Zed already installed" -ForegroundColor DarkGray
} elseif ($DryRun) {
    Write-Host "  [dry-run] Would install Zed via winget" -ForegroundColor Cyan
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
# 2. 同步設定檔（idempotent）
# ------------------------------------------------------------
Write-Host "[2/2] Syncing config files..." -ForegroundColor Yellow

$zedDst = Join-Path $env:APPDATA "Zed"

function Sync-ConfigFile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Label,
        [switch]$DryRun
    )
    if (Test-Path $Destination) {
        $srcHash = (Get-FileHash -Path $Source -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -Path $Destination -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) {
            Write-Host "  [skip] $Label unchanged" -ForegroundColor DarkGray
            return
        }
        if ($DryRun) {
            Write-Host "  [dry-run] Would backup and overwrite $Label" -ForegroundColor Cyan
            return
        }
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item $Destination "$Destination.$timestamp.bak"
        Write-Host "  Backed up existing $Label" -ForegroundColor Yellow
    } elseif ($DryRun) {
        Write-Host "  [dry-run] Would install $Label -> $(Split-Path $Destination -Parent)" -ForegroundColor Cyan
        return
    }
    $destDir = Split-Path $Destination -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory $destDir -Force | Out-Null }
    Copy-Item $Source -Destination $Destination -Force
    Write-Host "  Installed: $Label -> $(Split-Path $Destination -Parent)" -ForegroundColor Green
}

foreach ($f in @("settings.json", "keymap.json")) {
    $src = Join-Path $PSScriptRoot $f
    if (Test-Path $src) {
        Sync-ConfigFile -Source $src -Destination (Join-Path $zedDst $f) -Label $f -DryRun:$DryRun
    }
}

$warnings.Add("settings.json 的 github_personal_access_token 需要手動更新（MCP GitHub 整合用）")
Write-Host ""

# ------------------------------------------------------------
# 警告彙整
# ------------------------------------------------------------
if ($warnings.Count -gt 0) {
    Write-Host "========== 警告 ==========" -ForegroundColor Yellow
    foreach ($w in $warnings) {
        Write-Host "  !! $w" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "========== Zed Bootstrap Complete ==========" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY-RUN] 以上為預覽，實際執行請移除 -DryRun 參數`n" -ForegroundColor Magenta }
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "  - Config:    $env:APPDATA\Zed\settings.json" -ForegroundColor DarkGray
Write-Host "  - Keymap:    $env:APPDATA\Zed\keymap.json" -ForegroundColor DarkGray
Write-Host "  - MCP token: settings.json 內 github_personal_access_token 需手動填入" -ForegroundColor DarkGray
Write-Host ""

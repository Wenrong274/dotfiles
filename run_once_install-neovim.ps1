# run_once_install-neovim.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 負責：安裝 Neovim、PowerShell 7、im-select.exe、還原 lazy plugins
# 設定檔本身由 chezmoi 管理，不在此腳本處理

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

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
Write-Host "[1/3] Installing software via winget..." -ForegroundColor Yellow

$packages = @(
    @{ id = "Neovim.Neovim";        name = "Neovim" },
    @{ id = "Microsoft.PowerShell"; name = "PowerShell 7" }
)

foreach ($pkg in $packages) {
    winget list --id $pkg.id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [skip] $($pkg.name) already installed" -ForegroundColor DarkGray
    } else {
        Write-Host "  Installing $($pkg.name)..." -ForegroundColor Green
        winget install --id $pkg.id --exact --source winget `
            --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [error] winget install $($pkg.name) failed (exit $LASTEXITCODE)" -ForegroundColor Red
            exit 1
        }
    }
}
Write-Host ""

# ------------------------------------------------------------
# 2. 下載 im-select.exe（IME 自動切換）
# ------------------------------------------------------------
Write-Host "[2/3] Setting up im-select.exe..." -ForegroundColor Yellow

$toolsDir      = Join-Path $env:USERPROFILE "tools"
$imSelectPath  = Join-Path $toolsDir "im-select.exe"
$imSelectCommit = "11ed9277fb3118b63b36cfca57c39fa4cc882512"
$imSelectSha256 = "E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6"
$imSelectUrl   = "https://raw.githubusercontent.com/daipeihust/im-select/$imSelectCommit/win/out/x64/im-select.exe"

function Test-ImSelectHash { param([string]$Path)
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
            exit 1
        }
        Move-Item -Path $tmpPath -Destination $imSelectPath -Force
        Write-Host "  Saved to: $imSelectPath (SHA256 verified)" -ForegroundColor Green
    } catch {
        if (Test-Path $tmpPath) { Remove-Item $tmpPath -Force }
        Write-Host "  [warn] Download failed: $($_.Exception.Message)" -ForegroundColor Yellow
        $warnings.Add("im-select.exe 下載失敗 — 請手動安裝: $imSelectUrl")
    }
}
Write-Host ""

# ------------------------------------------------------------
# 3. 首次安裝 plugins 並 restore 到 lock 版本
# ------------------------------------------------------------
Write-Host "[3/3] Installing & restoring Neovim plugins..." -ForegroundColor Yellow

$nvimExe = (Get-Command nvim -ErrorAction SilentlyContinue).Source
if (-not $nvimExe) {
    $defaultPath = "$env:ProgramFiles\Neovim\bin\nvim.exe"
    if (Test-Path $defaultPath) { $nvimExe = $defaultPath }
}

if ($nvimExe) {
    Write-Host "  Running: $nvimExe --headless `"+Lazy! restore`" `"+qa`"" -ForegroundColor Green
    $lazyOutput = & $nvimExe --headless "+Lazy! restore" "+qa" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Plugins restored to locked commits" -ForegroundColor Green
    } else {
        Write-Host "  [warn] :Lazy restore exited with $LASTEXITCODE" -ForegroundColor Yellow
        $lazyOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        $warnings.Add(":Lazy restore 失敗 (exit $LASTEXITCODE) — 開啟 nvim 手動執行 :Lazy restore")
    }
} else {
    Write-Host "  [skip] nvim not found on PATH or default location" -ForegroundColor DarkGray
    Write-Host "         Open a new shell and run: nvim --headless +Lazy! restore +qa" -ForegroundColor DarkGray
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

Write-Host "========== Neovim Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "Paths:" -ForegroundColor Yellow
Write-Host "  Neovim:    $env:ProgramFiles\Neovim\bin\nvim.exe" -ForegroundColor DarkGray
Write-Host "  im-select: $env:USERPROFILE\tools\im-select.exe" -ForegroundColor DarkGray
Write-Host "  Config:    $env:LOCALAPPDATA\nvim\init.lua  (managed by chezmoi)" -ForegroundColor DarkGray
Write-Host ""

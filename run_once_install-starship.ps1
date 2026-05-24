# run_once_install-starship.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝 Starship prompt 及 Clink（CMD 整合用）

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Starship ==========" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[error] winget not found." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# 1. 安裝 Starship
# ------------------------------------------------------------
Write-Host "[1/2] Installing Starship..." -ForegroundColor Yellow

winget list --id Starship.Starship --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] Starship already installed" -ForegroundColor DarkGray
} else {
    winget install --id Starship.Starship --exact --source winget `
        --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [error] winget install Starship failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    Write-Host "  Starship installed" -ForegroundColor Green
}
Write-Host ""

# ------------------------------------------------------------
# 2. 安裝 Clink（CMD 整合需要）
# ------------------------------------------------------------
Write-Host "[2/2] Installing Clink (for CMD integration)..." -ForegroundColor Yellow

winget list --id chrisant996.Clink --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] Clink already installed" -ForegroundColor DarkGray
} else {
    winget install --id chrisant996.Clink --exact --source winget `
        --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [warn] winget install Clink failed (exit $LASTEXITCODE)" -ForegroundColor Yellow
        $warnings.Add("Clink 安裝失敗 — CMD 的 Starship 整合將無法運作，請手動安裝: https://chrisant996.github.io/clink/")
    } else {
        Write-Host "  Clink installed" -ForegroundColor Green
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

Write-Host "========== Starship Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "Paths:" -ForegroundColor Yellow
Write-Host "  Config:  ~/.config/starship.toml  (managed by chezmoi)" -ForegroundColor DarkGray
Write-Host "  CMD:     %LOCALAPPDATA%\clink\starship.lua  (managed by chezmoi)" -ForegroundColor DarkGray
Write-Host "  pwsh:    added to PowerShell profile automatically" -ForegroundColor DarkGray
Write-Host "  bash:    ~/.bashrc  (managed by chezmoi)" -ForegroundColor DarkGray
Write-Host ""

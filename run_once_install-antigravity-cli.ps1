# run_once_install-antigravity-cli.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝 Antigravity CLI（使用官方 Windows PowerShell installer）

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Antigravity CLI ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 安裝 Antigravity CLI
# ------------------------------------------------------------
$agyExe = Get-Command agy -ErrorAction SilentlyContinue
if ($agyExe) {
    $version = $null
    try {
        $versionOutput = & agy --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $version = $versionOutput | Select-Object -First 1
        }
    } catch {
        $version = $null
    }

    if ($version) {
        Write-Host "  [skip] Antigravity CLI already installed ($version)" -ForegroundColor DarkGray
    } else {
        Write-Host "  [skip] Antigravity CLI already installed" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  Installing Antigravity CLI..." -ForegroundColor Green
    $installerPath = Join-Path $env:TEMP "antigravity-cli-install.ps1"
    try {
        Invoke-WebRequest -Uri "https://antigravity.google/cli/install.ps1" -OutFile $installerPath -UseBasicParsing
        Write-Host "  Installer downloaded to: $installerPath" -ForegroundColor DarkGray
        & $installerPath
    } catch {
        Write-Host "  [error] Antigravity CLI installer 下載或執行失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "          請確認網路連線後重新執行: chezmoi apply" -ForegroundColor DarkGray
        exit 1
    } finally {
        if (Test-Path $installerPath) { Remove-Item $installerPath -Force -ErrorAction SilentlyContinue }
    }

    $agyExe = Get-Command agy -ErrorAction SilentlyContinue
    if (-not $agyExe) {
        Write-Host "  [error] agy not found after install" -ForegroundColor Red
        Write-Host "          Open a new shell and re-run: chezmoi apply" -ForegroundColor DarkGray
        exit 1
    }
    $installedVersion = $null
    try {
        $verOut = & agy --version 2>&1
        if ($LASTEXITCODE -eq 0) { $installedVersion = $verOut | Select-Object -First 1 }
    } catch { $installedVersion = $null }
    if ($installedVersion) {
        Write-Host "  Antigravity CLI installed ($installedVersion)" -ForegroundColor Green
    } else {
        Write-Host "  Antigravity CLI installed" -ForegroundColor Green
        $warnings.Add("agy --version 失敗 — 重新開啟 shell 後再確認版本")
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

Write-Host "========== Antigravity CLI Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "  登入：agy  （首次執行會引導 Google OAuth / keyring 登入）" -ForegroundColor DarkGray
Write-Host ""

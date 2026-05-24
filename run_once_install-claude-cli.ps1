# run_once_install-claude-cli.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝 Claude Code CLI（Node.js 若未安裝會自行透過 winget 安裝）

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Claude CLI ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 前置檢查：Node.js / npm（若未安裝則自行透過 winget 安裝）
# ------------------------------------------------------------
$npmExe = Get-Command npm -ErrorAction SilentlyContinue

if (-not $npmExe) {
    # winget 剛裝完 PATH 可能尚未刷新，試 fallback 路徑
    $fallback = @(
        "$env:ProgramFiles\nodejs\npm.cmd",
        "$env:APPDATA\npm\npm.cmd"
    )
    $found = $fallback | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($found) {
        $npmExe = $found
    } else {
        # Node.js 尚未安裝，直接在此安裝（不依賴 run_onchange_install-zed.ps1 的執行順序）
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Host "  [error] winget not found." -ForegroundColor Red
            Write-Host "          Install 'App Installer' from Microsoft Store, then re-run." -ForegroundColor DarkGray
            exit 1
        }
        Write-Host "  Node.js not found — installing via winget..." -ForegroundColor Yellow
        winget install --id OpenJS.NodeJS.LTS --exact --source winget `
            --accept-source-agreements --accept-package-agreements --disable-interactivity
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [error] Node.js install failed (exit $LASTEXITCODE)" -ForegroundColor Red
            exit 1
        }
        $fallbackAfterInstall = "$env:ProgramFiles\nodejs\npm.cmd"
        if (Test-Path $fallbackAfterInstall) {
            $npmExe = $fallbackAfterInstall
        } else {
            Write-Host "  [error] npm still not found after installing Node.js" -ForegroundColor Red
            Write-Host "          Open a new shell and re-run: chezmoi apply" -ForegroundColor DarkGray
            exit 1
        }
    }
}

Write-Host "  npm: $($npmExe.Source ?? $npmExe)" -ForegroundColor DarkGray
Write-Host ""

# ------------------------------------------------------------
# 安裝 Claude Code
# ------------------------------------------------------------
$claudeExe = Get-Command claude -ErrorAction SilentlyContinue
if ($claudeExe) {
    $version = & claude --version 2>&1 | Select-Object -First 1
    Write-Host "  [skip] Claude CLI already installed ($version)" -ForegroundColor DarkGray
} else {
    Write-Host "  Installing @anthropic-ai/claude-code..." -ForegroundColor Green
    & $npmExe install -g @anthropic-ai/claude-code
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [error] npm install failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    Write-Host "  Claude CLI installed" -ForegroundColor Green
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

Write-Host "========== Claude CLI Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "  登入：claude  （首次執行會引導 OAuth 登入）" -ForegroundColor DarkGray
Write-Host ""

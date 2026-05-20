# run_once_install-claude-cli.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝 Claude Code CLI（需要 Node.js，由 run_onchange_install-zed.ps1 負責安裝）

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Claude CLI ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 前置檢查：Node.js / npm
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
        Write-Host "  [error] npm not found — install Node.js first (run_onchange_install-zed.ps1)" -ForegroundColor Red
        exit 1
    }
}

Write-Host "  npm: $($npmExe.Source ?? $npmExe)" -ForegroundColor DarkGray
Write-Host ""

# ------------------------------------------------------------
# 安裝 Claude Code
# ------------------------------------------------------------
Write-Host "  Installing @anthropic-ai/claude-code..." -ForegroundColor Green

# 檢查是否已安裝
$claudeExe = Get-Command claude -ErrorAction SilentlyContinue
if ($claudeExe) {
    $version = & claude --version 2>&1 | Select-Object -First 1
    Write-Host "  [skip] Claude CLI already installed ($version)" -ForegroundColor DarkGray
} else {
    npm install -g @anthropic-ai/claude-code
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

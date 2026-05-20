# run_onchange_setup-pwsh-starship.ps1
# 把 Starship init 加進 PowerShell 7 profile
# run_onchange_：腳本內容變更時重跑，確保任何機器都有最新設定
# 使用 $PROFILE 取得正確路徑（處理 OneDrive 重新導向的 Documents）

$ErrorActionPreference = "Stop"

Write-Host "========== Setup: PowerShell Starship ==========" -ForegroundColor Cyan
Write-Host ""

# 使用 CurrentUserCurrentHost profile（只影響 pwsh，不動 Windows PowerShell 5）
$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir  = Split-Path $profilePath -Parent

if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    Write-Host "  [skip] starship not found on PATH — run run_once_install-starship.ps1 first" -ForegroundColor Yellow
    exit 0
}

# 建立 profile 目錄（如不存在）
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# 檢查是否已有 Starship init
if (Test-Path $profilePath) {
    $content = Get-Content $profilePath -Raw -Encoding UTF8
    if ($content -match 'starship init') {
        Write-Host "  [skip] Starship already configured in $profilePath" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "========== PowerShell Starship Setup Complete ==========" -ForegroundColor Cyan
        exit 0
    }
}

# 追加到 profile 尾端
$snippet = @"


# ── Starship prompt ──────────────────────────────────────────
Invoke-Expression (&starship init powershell)
"@

Add-Content -Path $profilePath -Value $snippet -Encoding UTF8
Write-Host "  Starship added to: $profilePath" -ForegroundColor Green
Write-Host ""
Write-Host "========== PowerShell Starship Setup Complete ==========" -ForegroundColor Cyan
Write-Host "  Restart pwsh or run: . `$PROFILE" -ForegroundColor DarkGray
Write-Host ""

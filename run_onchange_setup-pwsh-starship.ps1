# run_onchange_setup-pwsh-starship.ps1
# 把 Starship init 加進 PowerShell 7 profile
# run_onchange_：腳本內容變更時重跑，確保任何機器都有最新設定
# 使用 $PROFILE 取得正確路徑（處理 OneDrive 重新導向的 Documents）

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Setup: PowerShell Starship ==========" -ForegroundColor Cyan
Write-Host ""

# 使用 CurrentUserCurrentHost profile（只影響 pwsh，不動 Windows PowerShell 5）
$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir  = Split-Path $profilePath -Parent

if ((Test-Path $profilePath) -and ((Get-Content $profilePath -Raw -Encoding UTF8) -match 'starship init')) {
    Write-Host "  [skip] Starship already configured in $profilePath" -ForegroundColor DarkGray
    Write-Host ""
} else {
    # starship 可能剛透過 winget 安裝、PATH 尚未刷新，不以 Get-Command 判斷
    # profile 寫入後，下次 pwsh 啟動時 PATH 已更新，starship init 就會生效
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # 追加到 profile 尾端
    $snippet = @"


# ── Starship prompt ──────────────────────────────────────────
Invoke-Expression (&starship init powershell)
"@

    Add-Content -Path $profilePath -Value $snippet -Encoding UTF8
    Write-Host "  Starship added to: $profilePath" -ForegroundColor Green
    Write-Host ""
}

# ------------------------------------------------------------
# 警告彙整
# ------------------------------------------------------------
if ($warnings.Count -gt 0) {
    Write-Host "========== 警告 ==========" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  !! $w" -ForegroundColor Yellow }
    Write-Host ""
}

Write-Host "========== PowerShell Starship Setup Complete ==========" -ForegroundColor Cyan
Write-Host "  Restart pwsh or run: . `$PROFILE" -ForegroundColor DarkGray
Write-Host ""

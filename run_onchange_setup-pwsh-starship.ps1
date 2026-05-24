# run_onchange_setup-pwsh-starship.ps1
# 把 Starship init 加進 PowerShell 7 profile
# run_onchange_：腳本內容變更時重跑，確保任何機器都有最新設定
# 使用 $PROFILE 取得正確路徑（處理 OneDrive 重新導向的 Documents）
# managed block markers 讓未來更新 snippet 時可精確定位並替換，不依賴模糊字串判斷

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Setup: PowerShell Starship ==========" -ForegroundColor Cyan
Write-Host ""

# 使用 CurrentUserCurrentHost profile（只影響 pwsh，不動 Windows PowerShell 5）
$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir  = Split-Path $profilePath -Parent

# managed block markers（用於精確識別並替換已部署的 snippet）
$markerStart = '# >>> chezmoi-starship >>>'
$markerEnd   = '# <<< chezmoi-starship <<<'

$snippet = @"
$markerStart
# Guard：starship 不在 PATH 時跳過，避免 pwsh 啟動報錯（例如 starship 被移除或 PATH 異常）
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
$markerEnd
"@

$content = if (Test-Path $profilePath) { Get-Content $profilePath -Raw -Encoding UTF8 } else { '' }

if ($content.Contains($markerStart)) {
    # 已有 managed block — 比對是否為最新版本（正規化換行後比較）
    $blockRegex = '(?s)' + [regex]::Escape($markerStart) + '.*?' + [regex]::Escape($markerEnd)
    $existing   = ([regex]::Match($content, $blockRegex).Value -replace '\r\n', "`n").Trim()
    $target     = ($snippet -replace '\r\n', "`n").Trim()
    if ($existing -eq $target) {
        Write-Host "  [skip] Starship already up-to-date in:" -ForegroundColor DarkGray
        Write-Host "         $profilePath" -ForegroundColor DarkGray
    } else {
        $newContent = [regex]::Replace($content, $blockRegex, $target)
        Set-Content -Path $profilePath -Value $newContent.TrimEnd() -Encoding UTF8 -NoNewline
        Write-Host "  Starship snippet updated in: $profilePath" -ForegroundColor Green
    }
} else {
    # 尚未有 managed block — 建立 profile 目錄（若不存在）再寫入
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }

    # 舊版 snippet 有 banner「# ── Starship prompt ──…」，搭配兩種形式：
    #   1. 未加 guard 的舊版（只有 Invoke-Expression 一行）
    #   2. 加了 guard 但尚未有 markers 的中間版本（if/Invoke-Expression/}）
    # 偵測並替換為 managed block；若找不到則追加。
    $oldBlockRegex = (
        '(?:\r?\n){1,3}' +                                           # 前置空行（1–3 行）
        '# [^\r\n]*Starship prompt[^\r\n]*' +                        # banner 行
        '(?:' +
            '\r?\nInvoke-Expression \(&starship init powershell\)' + # 舊版：無 guard
        '|' +
            '\r?\nif \(Get-Command starship[^\r\n]+\) \{' +          # 新版：有 guard 開頭
            '(?:\r?\n[^\r\n]*Invoke-Expression \(&starship init powershell\))+' +
            '\r?\n\}' +                                              # guard 結尾
        ')'
    )

    if ($content -match $oldBlockRegex) {
        # 找到舊 snippet → 替換為 managed block
        $newContent = $content -replace $oldBlockRegex, "`n`n`n$($snippet.Trim())"
        Set-Content -Path $profilePath -Value $newContent.TrimEnd() -Encoding UTF8 -NoNewline
        Write-Host "  Starship snippet upgraded to managed block in: $profilePath" -ForegroundColor Green
    } else {
        # 全新 profile 或無 starship 設定 → 直接追加
        $appendText = if ($content.Length -gt 0) { "`n`n`n$($snippet.Trim())`n" } else { "$($snippet.Trim())`n" }
        Add-Content -Path $profilePath -Value $appendText -Encoding UTF8
        Write-Host "  Starship added to: $profilePath" -ForegroundColor Green
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

Write-Host "========== PowerShell Starship Setup Complete ==========" -ForegroundColor Cyan
Write-Host "  Restart pwsh or run: . `$PROFILE" -ForegroundColor DarkGray
Write-Host ""

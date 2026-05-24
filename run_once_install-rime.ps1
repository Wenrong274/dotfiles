# run_once_install-rime.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝 小狼毫 (Weasel) 輸入法，並部署 rime-config 設定檔（private repo）

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Rime / Weasel ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 前置檢查
# ------------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[error] winget not found." -ForegroundColor Red
    Write-Host "        Install 'App Installer' from Microsoft Store, then re-run." -ForegroundColor DarkGray
    Write-Host "        https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor DarkGray
    exit 1
}

# ------------------------------------------------------------
# 1. 安裝 Weasel（小狼毫）
# ------------------------------------------------------------
Write-Host "[1/2] Installing Weasel (小狼毫)..." -ForegroundColor Yellow

winget list --id Rime.Weasel --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] Weasel already installed" -ForegroundColor DarkGray
} else {
    Write-Host "  Installing Weasel..." -ForegroundColor Green
    winget install --id Rime.Weasel --exact --source winget `
        --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [error] Weasel install failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    Write-Host "  Weasel installed" -ForegroundColor Green
}
Write-Host ""

# ------------------------------------------------------------
# 2. 部署 rime-config（private repo，需要 GitHub 憑證）
# 安全流程：先 clone 到 temp 目錄，成功後才備份/移入正式位置；
# clone 失敗時 $rimeDir 完全不受影響。
# Git PATH fallback：Git 可能剛由 winget 安裝但 PATH 尚未刷新，
# 自動嘗試 %ProgramFiles%\Git\cmd\git.exe。
# ------------------------------------------------------------
Write-Host "[2/2] Deploying rime-config..." -ForegroundColor Yellow

$rimeDir  = "$env:APPDATA\Rime"
$rimeRepo = "https://github.com/Wenrong274/rime-config.git"

# Git PATH fallback（winget 安裝後 shell PATH 可能尚未刷新）
$gitExe = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitExe) {
    $gitFallback = "$env:ProgramFiles\Git\cmd\git.exe"
    if (Test-Path $gitFallback) {
        $gitExe = $gitFallback
        Write-Host "  [warn] git not in PATH — using fallback: $gitFallback" -ForegroundColor Yellow
    }
}

if (-not $gitExe) {
    Write-Host "  [warn] git not found — skipping config deployment" -ForegroundColor Yellow
    $warnings.Add("rime-config 未部署 — git 不在 PATH，請安裝 Git 後手動執行:")
    $warnings.Add("  git clone $rimeRepo `"$rimeDir`"")
} elseif (Test-Path "$rimeDir\.git") {
    Write-Host "  [skip] $rimeDir is already a git repo" -ForegroundColor DarkGray
} else {
    # 先 clone 到 temp，避免 clone 失敗時原設定已被移走
    $tmpClone = Join-Path $env:TEMP "rime-config-bootstrap-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    Write-Host "  Cloning rime-config (requires GitHub credentials)..." -ForegroundColor Green
    & $gitExe clone $rimeRepo "$tmpClone" 2>&1
    if ($LASTEXITCODE -ne 0) {
        if (Test-Path $tmpClone) { Remove-Item $tmpClone -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Host "  [warn] git clone failed (exit $LASTEXITCODE)" -ForegroundColor Yellow
        $warnings.Add("rime-config 部署失敗 — 確認 GitHub 憑證後手動執行:")
        $warnings.Add("  git clone $rimeRepo `"$rimeDir`"")
    } else {
        # Clone 成功 → 清理 / 備份 $rimeDir 後，移入正式位置
        # 注意：Move-Item 遇到已存在目錄時會把來源搬「進去」而非「取代」，
        # 因此 $rimeDir 不論空或有內容，都必須先移走或刪除。
        if (Test-Path $rimeDir) {
            if (Get-ChildItem $rimeDir -ErrorAction SilentlyContinue) {
                # 有內容 → 備份，保留資料
                $backup = "$rimeDir.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                try {
                    Move-Item $rimeDir $backup -ErrorAction Stop
                } catch {
                    $backup = "$rimeDir.backup-$(Get-Random)"
                    Write-Host "  [warn] backup path conflict, retrying as: $backup" -ForegroundColor Yellow
                    Move-Item $rimeDir $backup
                }
                Write-Host "  [warn] existing files backed up to: $backup" -ForegroundColor Yellow
            } else {
                # 空目錄 → 直接刪除，否則 Move-Item 會把 clone 搬入 Rime\ 而非取代
                Remove-Item $rimeDir -Force
            }
        }
        Move-Item $tmpClone $rimeDir
        Write-Host "  rime-config deployed to: $rimeDir" -ForegroundColor Green
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

Write-Host "========== Rime Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "  設定檔: $rimeDir" -ForegroundColor DarkGray
Write-Host "  安裝後請重新部署 Rime：右鍵小狼毫圖示 → 重新部署" -ForegroundColor DarkGray
Write-Host ""

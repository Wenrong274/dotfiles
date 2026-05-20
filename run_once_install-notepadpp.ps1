# run_once_install-notepadpp.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 負責：安裝 Notepad++、安裝插件
# 設定檔（config.xml 等）由 chezmoi 管理，不在此腳本處理

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Notepad++ ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 前置檢查
# ------------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[error] winget not found." -ForegroundColor Red
    exit 1
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[warn] 未以系統管理員身分執行，插件安裝步驟將略過" -ForegroundColor Yellow
    Write-Host "       若要安裝插件，請以系統管理員身分重新執行此腳本" -ForegroundColor DarkGray
    Write-Host ""
}

# ------------------------------------------------------------
# 1. 安裝 Notepad++
# ------------------------------------------------------------
Write-Host "[1/2] Installing Notepad++..." -ForegroundColor Yellow

winget list --id Notepad++.Notepad++ --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] Notepad++ already installed" -ForegroundColor DarkGray
} else {
    winget install --id Notepad++.Notepad++ --exact --source winget `
        --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [error] winget install Notepad++ failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# ------------------------------------------------------------
# 2. 安裝插件（需要 Admin）
# ------------------------------------------------------------
Write-Host "[2/2] Installing plugins..." -ForegroundColor Yellow

if (-not $isAdmin) {
    Write-Host "  [skip] 跳過插件安裝（非 Admin）" -ForegroundColor DarkGray
    $warnings.Add("plugins 未安裝 — 請以系統管理員重新執行此腳本")
} else {
    # plugins.json 與此腳本放在同一目錄（chezmoi source root）
    $pluginsJson = Join-Path $PSScriptRoot "notepadpp\plugins.json"
    if (-not (Test-Path $pluginsJson)) {
        # fallback: 同層
        $pluginsJson = Join-Path $PSScriptRoot "plugins.json"
    }

    try {
        $plugins = Get-Content $pluginsJson -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Host "  [error] plugins.json 讀取失敗: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

    $nppPluginDir = "$env:ProgramFiles\Notepad++\plugins"
    $tmpDir       = Join-Path $env:TEMP "npp-plugins-bootstrap"

    try {
        foreach ($plugin in $plugins) {
            $pluginDest = Join-Path $nppPluginDir $plugin.name

            if (Test-Path (Join-Path $pluginDest "$($plugin.name).dll")) {
                Write-Host "  [skip] $($plugin.name) already installed" -ForegroundColor DarkGray
                continue
            }

            Write-Host "  Installing $($plugin.name) v$($plugin.version)..." -ForegroundColor Green

            $zipPath    = Join-Path $tmpDir "$($plugin.name).zip"
            $extractDir = Join-Path $tmpDir $plugin.name

            New-Item -ItemType Directory $tmpDir -Force | Out-Null

            try {
                Invoke-WebRequest -Uri $plugin.url -OutFile $zipPath -UseBasicParsing

                if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
                Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

                if (-not (Test-Path $pluginDest)) { New-Item -ItemType Directory $pluginDest -Force | Out-Null }

                Get-ChildItem $extractDir -Recurse -Filter "*.dll" | ForEach-Object {
                    Copy-Item $_.FullName -Destination $pluginDest -Force
                }
                Write-Host "    Done" -ForegroundColor Green
            } catch {
                Write-Host "    [warn] Failed: $($_.Exception.Message)" -ForegroundColor Yellow
                $warnings.Add("$($plugin.name) 安裝失敗，請手動安裝: $($plugin.url)")
            }
        }
    } finally {
        if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
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

Write-Host "========== Notepad++ Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "Paths:" -ForegroundColor Yellow
Write-Host "  Plugins: $env:ProgramFiles\Notepad++\plugins\" -ForegroundColor DarkGray
Write-Host "  Config:  $env:APPDATA\Notepad++\  (managed by chezmoi)" -ForegroundColor DarkGray
Write-Host ""

# notepadpp/install.ps1 — Notepad++ 環境一鍵設定
# Usage: .\notepadpp\install.ps1
#        .\notepadpp\install.ps1 -DryRun
#
# 注意：安裝插件需要系統管理員權限（寫入 Program Files）
# 建議從 bootstrap.ps1 呼叫，或以系統管理員身分單獨執行

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Notepad++ ==========" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY-RUN] 預覽模式，不會實際修改任何東西`n" -ForegroundColor Magenta }
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
if (-not $isAdmin -and -not $DryRun) {
    Write-Host "[warn] 未以系統管理員身分執行，插件安裝步驟將略過" -ForegroundColor Yellow
    Write-Host "       若要安裝插件，請以系統管理員身分重新執行此腳本" -ForegroundColor DarkGray
    Write-Host ""
}

. (Join-Path $PSScriptRoot "..\lib\sync-config.ps1")

# ------------------------------------------------------------
# 1. 安裝 Notepad++
# ------------------------------------------------------------
Write-Host "[1/3] Installing Notepad++..." -ForegroundColor Yellow

winget list --id Notepad++.Notepad++ --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] Notepad++ already installed" -ForegroundColor DarkGray
} elseif ($DryRun) {
    Write-Host "  [dry-run] Would install Notepad++ via winget" -ForegroundColor Cyan
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
Write-Host "[2/3] Installing plugins..." -ForegroundColor Yellow

if (-not $isAdmin -and -not $DryRun) {
    Write-Host "  [skip] 跳過插件安裝（非 Admin）" -ForegroundColor DarkGray
    $warnings.Add("plugins 未安裝 — 非 Admin 身分執行，請以系統管理員重新執行此腳本")
} else {
    $pluginsJson = Join-Path $PSScriptRoot "plugins.json"
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

            if ($DryRun) {
                Write-Host "  [dry-run] Would install $($plugin.name) v$($plugin.version)" -ForegroundColor Cyan
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

                # Copy all DLLs (handles both flat and nested ZIP structures)
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
# 3. 同步設定檔
# ------------------------------------------------------------
Write-Host "[3/3] Syncing config files..." -ForegroundColor Yellow

$configSrcDir = Join-Path $PSScriptRoot "config"
$configDstDir = Join-Path $env:APPDATA "Notepad++"

foreach ($f in @("config.xml", "shortcuts.xml", "stylers.xml", "langs.xml", "contextMenu.xml")) {
    $src = Join-Path $configSrcDir $f
    if (Test-Path $src) {
        Sync-ConfigFile -Source $src -Destination (Join-Path $configDstDir $f) -Label $f -DryRun:$DryRun
    }
}
Write-Host ""

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
if ($warnings.Count -gt 0) {
    Write-Host "========== 警告 ==========" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  !! $w" -ForegroundColor Yellow }
    Write-Host ""
}

Write-Host "========== Notepad++ Bootstrap Complete ==========" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY-RUN] 以上為預覽，實際執行請移除 -DryRun 參數`n" -ForegroundColor Magenta }
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "  - Plugins:    $env:ProgramFiles\Notepad++\plugins\" -ForegroundColor DarkGray
Write-Host "  - Config:     $env:APPDATA\Notepad++\" -ForegroundColor DarkGray
Write-Host "  - 更新版本:   編輯 $(Join-Path $PSScriptRoot 'plugins.json')" -ForegroundColor DarkGray
Write-Host ""

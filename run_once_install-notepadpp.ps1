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
    # chezmoi 執行腳本時 $PSScriptRoot 指向暫存目錄，無法讀取旁邊的檔案，
    # 因此直接將 plugins 資料嵌入腳本。
    $plugins = @(
        [PSCustomObject]@{ name = "AutoSave";      version = "2.0.0";    url = "https://github.com/francostellari/NppPlugins/raw/main/AutoSave/AutoSave_dll_2v00_x64.zip" }
        [PSCustomObject]@{ name = "ComparePlugin"; version = "2.0.2";    url = "https://github.com/pnedev/compare-plugin/releases/download/v2.0.2/ComparePlugin_v2.0.2_X64.zip" }
        [PSCustomObject]@{ name = "ComparePlus";   version = "3.0.0";    url = "https://github.com/pnedev/comparePlus/releases/download/cp_3.0.0/ComparePlus_cp_3.0.0_x64.zip" }
        [PSCustomObject]@{ name = "CSVLint";       version = "0.4.7";    url = "https://github.com/BdR76/CSVLint/releases/download/0.4.7/CSVLint_x64.zip" }
        [PSCustomObject]@{ name = "DSpellCheck";   version = "1.5.0";    url = "https://github.com/Predelnik/DSpellCheck/releases/download/v1.5.0/DSpellCheck_x64.zip" }
        [PSCustomObject]@{ name = "MultiReplace";  version = "5.0.0.35"; url = "https://github.com/daddel80/notepadpp-multireplace/releases/download/5.0.0.35/MultiReplace-v5.0.0.35-x64.zip" }
        [PSCustomObject]@{ name = "NPPJSONViewer"; version = "2.1.1.0";  url = "https://github.com/NPP-JSONViewer/JSON-Viewer/releases/download/v2.1.1.0/NppJSONViewer_x64_Release.zip" }
        [PSCustomObject]@{ name = "NppTextFX";     version = "2.0.3";    url = "https://github.com/rainman74/NPPTextFX2/releases/download/2.0.3/NppTextFX2.2.0.3.x64.zip" }
        [PSCustomObject]@{ name = "XMLTools";      version = "3.1.1.13"; url = "https://github.com/morbac/xmltools/releases/download/3.1.1.13/XMLTools-3.1.1.13-x64.zip" }
    )

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

# run_once_install-fonts.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝 Zed / Neovim / VSCode / Starship 設定所需的字型（不需要系統管理員）
#
# 安裝清單：
#   - Hack Nerd Font         (Zed terminal.font_family, VSCode terminal)
#   - JetBrains Mono NF      (Zed buffer_font_family)
#   - FiraCode Nerd Font      (Zed buffer_font_fallbacks)
#   - Noto Sans TC            (Zed buffer_font_fallbacks, CJK fallback)
#   - Symbols Nerd Font Mono  (terminal icon fallback; lightweight icon-only font)
#
# 字型安裝到使用者目錄（%LOCALAPPDATA%\Microsoft\Windows\Fonts\）
# 不需要 Admin，Windows 10/11 會自動識別

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Fonts ==========" -ForegroundColor Cyan
Write-Host ""

# Nerd Fonts 版本（鎖定，確保跨機一致）
$nerdFontsVersion = "v3.4.0"
$notoSansCjkVersion = "Sans2.004"

$userFontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$regPath      = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
$tmpDir       = Join-Path $env:TEMP "fonts-bootstrap"

New-Item -ItemType Directory -Path $userFontsDir -Force | Out-Null
New-Item -ItemType Directory -Path $tmpDir       -Force | Out-Null
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

# ------------------------------------------------------------
# 工具函式
# ------------------------------------------------------------

# 安裝單一字型檔（TTF/OTF）到使用者目錄並登錄
function Install-FontFile {
    param([string]$Path)
    $fileName = Split-Path $Path -Leaf
    $dest     = Join-Path $userFontsDir $fileName

    if (Test-Path $dest) {
        Write-Host "    [skip] $fileName already installed" -ForegroundColor DarkGray
        return
    }

    Copy-Item $Path -Destination $dest -Force

    # 取得字型顯示名稱（讀 name table，fallback 到檔名去副檔名）
    $displayName = try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $fontCollection = New-Object System.Drawing.Text.PrivateFontCollection
        $fontCollection.AddFontFile($dest)
        $families = $fontCollection.Families | Select-Object -ExpandProperty Name
        $fontCollection.Dispose()
        if ($families) { "$($families[0]) (TrueType)" } else { $null }
    } catch { $null }

    if (-not $displayName) {
        $displayName = "$([System.IO.Path]::GetFileNameWithoutExtension($fileName)) (TrueType)"
    }

    Set-ItemProperty -Path $regPath -Name $displayName -Value $dest -ErrorAction SilentlyContinue
    Write-Host "    Installed: $fileName" -ForegroundColor Green
}

# 下載 ZIP，解壓，安裝符合 pattern 的字型檔
function Install-FontZip {
    param(
        [string]$Url,
        [string]$ZipName,
        [string[]]$Patterns   # e.g. @("*Regular*", "*Bold*", "*Italic*")
    )

    $zipPath    = Join-Path $tmpDir $ZipName
    $extractDir = Join-Path $tmpDir ([System.IO.Path]::GetFileNameWithoutExtension($ZipName))

    Write-Host "  Downloading $ZipName..." -ForegroundColor Green
    try {
        Invoke-WebRequest -Uri $Url -OutFile $zipPath -UseBasicParsing
    } catch {
        Write-Host "  [warn] Download failed: $($_.Exception.Message)" -ForegroundColor Yellow
        $warnings.Add("$ZipName 下載失敗，請手動安裝: $Url")
        return
    }

    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    # 找出符合 pattern 的 TTF/OTF（排除 Windows Compatible 變體）
    $fontFiles = Get-ChildItem $extractDir -Recurse -Include "*.ttf","*.otf" |
        Where-Object { $_.Name -notmatch "WindowsCompatible" }

    if ($Patterns) {
        $fontFiles = $fontFiles | Where-Object {
            $name = $_.Name
            $Patterns | Where-Object { $name -like $_ } | Select-Object -First 1
        }
    }

    foreach ($f in $fontFiles) { Install-FontFile -Path $f.FullName }
}

# ------------------------------------------------------------
# 1. Hack Nerd Font
# ------------------------------------------------------------
Write-Host "[1/5] Hack Nerd Font..." -ForegroundColor Yellow

$hackUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/$nerdFontsVersion/Hack.zip"
Install-FontZip -Url $hackUrl -ZipName "Hack.zip" -Patterns @(
    "HackNerdFont-Regular.ttf",
    "HackNerdFont-Bold.ttf",
    "HackNerdFont-Italic.ttf",
    "HackNerdFont-BoldItalic.ttf"
)
Write-Host ""

# ------------------------------------------------------------
# 2. JetBrains Mono Nerd Font
# ------------------------------------------------------------
Write-Host "[2/5] JetBrains Mono Nerd Font..." -ForegroundColor Yellow

$jbUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/$nerdFontsVersion/JetBrainsMono.zip"
Install-FontZip -Url $jbUrl -ZipName "JetBrainsMono.zip" -Patterns @(
    "JetBrainsMonoNerdFont-Regular.ttf",
    "JetBrainsMonoNerdFont-Bold.ttf",
    "JetBrainsMonoNerdFont-Italic.ttf",
    "JetBrainsMonoNerdFont-BoldItalic.ttf"
)
Write-Host ""

# ------------------------------------------------------------
# 3. FiraCode Nerd Font
# ------------------------------------------------------------
Write-Host "[3/5] FiraCode Nerd Font..." -ForegroundColor Yellow

$fcUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/$nerdFontsVersion/FiraCode.zip"
Install-FontZip -Url $fcUrl -ZipName "FiraCode.zip" -Patterns @(
    "FiraCodeNerdFont-Regular.ttf",
    "FiraCodeNerdFont-Bold.ttf",
    "FiraCodeNerdFont-Light.ttf",
    "FiraCodeNerdFont-Medium.ttf",
    "FiraCodeNerdFont-Retina.ttf",
    "FiraCodeNerdFont-SemiBold.ttf"
)
Write-Host ""

# ------------------------------------------------------------
# 4. Noto Sans TC（official Noto CJK release，CJK fallback）
# ------------------------------------------------------------
Write-Host "[4/5] Noto Sans TC..." -ForegroundColor Yellow
$notoUrl = "https://github.com/notofonts/noto-cjk/releases/download/$notoSansCjkVersion/19_NotoSansTC.zip"
Install-FontZip -Url $notoUrl -ZipName "NotoSansTC.zip" -Patterns $null
Write-Host ""

# ------------------------------------------------------------
# 5. Symbols Nerd Font Mono（icon-only fallback font）
# ------------------------------------------------------------
Write-Host "[5/5] Symbols Nerd Font Mono..." -ForegroundColor Yellow

$symUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/$nerdFontsVersion/NerdFontsSymbolsOnly.zip"
Install-FontZip -Url $symUrl -ZipName "NerdFontsSymbolsOnly.zip" -Patterns @(
    "SymbolsNerdFont-Regular.ttf",
    "SymbolsNerdFontMono-Regular.ttf"
)
Write-Host ""

# ------------------------------------------------------------
# 清理暫存
# ------------------------------------------------------------
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 警告彙整
# ------------------------------------------------------------
if ($warnings.Count -gt 0) {
    Write-Host "========== 警告 ==========" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  !! $w" -ForegroundColor Yellow }
    Write-Host ""
}

Write-Host "========== Fonts Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "  字型安裝到：$userFontsDir" -ForegroundColor DarkGray
Write-Host "  重新啟動 Zed / VSCode / Terminal 後生效" -ForegroundColor DarkGray
Write-Host ""

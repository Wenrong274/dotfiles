# bootstrap.ps1 — 新機器一鍵設定 VSCode + Neovim 環境
# Usage: git clone https://github.com/Wenrong274/dotfiles ~/dotfiles
#        cd ~/dotfiles && .\bootstrap.ps1
#
# 前提：Windows 10/11 + winget 可用 + VSCode 已安裝

$ErrorActionPreference = "Stop"

Write-Host "========== Bootstrap: VSCode + Neovim ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. 安裝核心軟體（winget）
# ------------------------------------------------------------
Write-Host "[1/4] Installing software via winget..." -ForegroundColor Yellow

$packages = @(
    @{ id = "Neovim.Neovim";         name = "Neovim" },
    @{ id = "Microsoft.PowerShell";   name = "PowerShell 7" }
)

foreach ($pkg in $packages) {
    $installed = winget list --id $pkg.id 2>$null | Select-String $pkg.id
    if ($installed) {
        Write-Host "  [skip] $($pkg.name) already installed" -ForegroundColor DarkGray
    } else {
        Write-Host "  Installing $($pkg.name)..." -ForegroundColor Green
        winget install --id $pkg.id --accept-source-agreements --accept-package-agreements
    }
}
Write-Host ""

# ------------------------------------------------------------
# 2. 下載 im-select.exe（IME 自動切換）
# ------------------------------------------------------------
Write-Host "[2/4] Setting up im-select.exe..." -ForegroundColor Yellow

$toolsDir = Join-Path $env:USERPROFILE "tools"
$imSelectPath = Join-Path $toolsDir "im-select.exe"

if (Test-Path $imSelectPath) {
    Write-Host "  [skip] im-select.exe already exists" -ForegroundColor DarkGray
} else {
    New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
    $url = "https://github.com/daipeihust/im-select/raw/master/win/out/x64/im-select.exe"
    Write-Host "  Downloading im-select.exe..." -ForegroundColor Green
    try {
        Invoke-WebRequest -Uri $url -OutFile $imSelectPath -UseBasicParsing
        Write-Host "  Saved to: $imSelectPath" -ForegroundColor Green
    } catch {
        Write-Host "  [warn] Download failed. Please download manually:" -ForegroundColor Red
        Write-Host "         $url" -ForegroundColor DarkGray
        Write-Host "         Save to: $imSelectPath" -ForegroundColor DarkGray
    }
}
Write-Host ""

# ------------------------------------------------------------
# 3. 安裝 VSCode 擴充
# ------------------------------------------------------------
Write-Host "[3/4] Installing VSCode extensions..." -ForegroundColor Yellow

$extensions = @(
    "asvetliakov.vscode-neovim"
    "pkief.material-icon-theme"
    "zhuangtongfa.material-theme"
    "ms-dotnettools.csharp"
    "ms-dotnettools.csdevkit"
    "ms-dotnettools.vscode-dotnet-runtime"
    "visualstudiotoolsforunity.vstuc"
    "kleber-swf.unity-code-snippets"
    "eamodio.gitlens"
    "davidanson.vscode-markdownlint"
    "yzhang.markdown-all-in-one"
    "streetsidesoftware.code-spell-checker"
    "aaron-bond.better-comments"
    "alefragnani.bookmarks"
    "codezombiech.gitignore"
    "editorconfig.editorconfig"
    "gruntfuggly.todo-tree"
    "mechatroner.rainbow-csv"
    "ms-vscode.powershell"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "oderwat.indent-rainbow"
    "shardulm94.trailing-spaces"
)

$installedExts = code --list-extensions 2>$null
$installCount = 0

foreach ($ext in $extensions) {
    if ($installedExts -contains $ext) {
        Write-Host "  [skip] $ext" -ForegroundColor DarkGray
    } else {
        code --install-extension $ext --force 2>$null | Out-Null
        Write-Host "  Installed: $ext" -ForegroundColor Green
        $installCount++
    }
}

Write-Host "  ($installCount new extensions installed)" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 4. 套用設定檔（呼叫 install.ps1）
# ------------------------------------------------------------
Write-Host "[4/4] Applying config files..." -ForegroundColor Yellow

$installScript = Join-Path $PSScriptRoot "install.ps1"
if (Test-Path $installScript) {
    & $installScript
} else {
    Write-Host "  [error] install.ps1 not found at: $installScript" -ForegroundColor Red
}

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
Write-Host ""
Write-Host "========== Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Reload VSCode (Ctrl+Shift+P -> Reload Window)" -ForegroundColor DarkGray
Write-Host "  2. First launch may take ~5s (lazy.nvim installs Neovim plugins)" -ForegroundColor DarkGray
Write-Host "  3. Verify: open a .cs file, press <Space>f to test Quick Open" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "  - Neovim path: C:\Program Files\Neovim\bin\nvim.exe" -ForegroundColor DarkGray
Write-Host "  - im-select:   $env:USERPROFILE\tools\im-select.exe" -ForegroundColor DarkGray
Write-Host "  - Neovim config: $env:LOCALAPPDATA\nvim\init.lua" -ForegroundColor DarkGray
Write-Host "  - VSCode config: $env:APPDATA\Code\User\settings.json" -ForegroundColor DarkGray
Write-Host ""

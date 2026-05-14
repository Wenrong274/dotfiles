# install.ps1 — restore VSCode + Neovim config from this dotfiles repo
# Usage: cd ~/dotfiles && .\install.ps1
#
# Substitutes __USERPROFILE__ placeholder with the current $env:USERPROFILE
# so machine-specific paths work after clone.

$ErrorActionPreference = "Stop"

$repoDir = $PSScriptRoot

# Destination map: repo subfolder -> filesystem path
$targets = @(
    @{ repo = "vscode"; dst = (Join-Path $env:APPDATA "Code\User") },
    @{ repo = "nvim";   dst = (Join-Path $env:LOCALAPPDATA "nvim") }
)

# JSON-escaped USERPROFILE for placeholder substitution
$userProfileJson = $env:USERPROFILE.Replace('\', '\\')
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

function Install-Files {
    param([string]$srcDir, [string]$dstDir)

    if (-not (Test-Path $srcDir)) {
        Write-Host "  (skip) source missing: $srcDir" -ForegroundColor DarkGray
        return
    }
    if (-not (Test-Path $dstDir)) {
        Write-Host "  Creating: $dstDir"
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    Write-Host "Installing $srcDir -> $dstDir" -ForegroundColor Cyan

    foreach ($f in Get-ChildItem $srcDir -File) {
        $dstPath = Join-Path $dstDir $f.Name

        if (Test-Path $dstPath) {
            $bakPath = "$dstPath.$timestamp.bak"
            Copy-Item $dstPath $bakPath
            Write-Host "  Backed up: $($f.Name) -> $($f.Name).$timestamp.bak" -ForegroundColor Yellow
        }

        # settings.json: substitute placeholder
        if ($f.Name -eq "settings.json" -or $f.Name -eq "init.lua") {
            $content = [System.IO.File]::ReadAllText($f.FullName)
            if ($content.Contains('__USERPROFILE__')) {
                $content = $content.Replace('__USERPROFILE__', $userProfileJson)
                [System.IO.File]::WriteAllText($dstPath, $content)
                Write-Host "  Installed: $($f.Name) (substituted __USERPROFILE__)" -ForegroundColor Green
            } else {
                Copy-Item $f.FullName -Destination $dstPath -Force
                Write-Host "  Installed: $($f.Name)" -ForegroundColor Green
            }
        } else {
            Copy-Item $f.FullName -Destination $dstPath -Force
            Write-Host "  Installed: $($f.Name)" -ForegroundColor Green
        }
    }
    Write-Host ""
}

foreach ($t in $targets) {
    Install-Files (Join-Path $repoDir $t.repo) $t.dst
}

Write-Host "Done. Reload VSCode (Ctrl+Shift+P -> Reload Window) to apply." -ForegroundColor Cyan
Write-Host ""
Write-Host "Reminders:" -ForegroundColor DarkGray
Write-Host "  - im-select.exe at ~\tools\ if Vim IME switching is needed:" -ForegroundColor DarkGray
Write-Host "    https://github.com/daipeihust/im-select/raw/master/win/out/x64/im-select.exe" -ForegroundColor DarkGray
Write-Host "  - Neovim binary at C:\Program Files\Neovim\bin\nvim.exe (winget install Neovim.Neovim)" -ForegroundColor DarkGray
Write-Host "  - VSCode extension: asvetliakov.vscode-neovim" -ForegroundColor DarkGray

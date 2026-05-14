# install.ps1 — restore VSCode user config from this dotfiles repo
# Usage: cd ~/dotfiles && .\install.ps1
#
# Substitutes __USERPROFILE__ placeholder with the current $env:USERPROFILE
# so machine-specific paths (e.g. im-select.exe location) work after clone.

$ErrorActionPreference = "Stop"

$repoDir = $PSScriptRoot
$srcDir = Join-Path $repoDir "vscode"
$dstDir = Join-Path $env:APPDATA "Code\User"

if (-not (Test-Path $srcDir)) {
    Write-Error "Source dir not found: $srcDir"
    exit 1
}

if (-not (Test-Path $dstDir)) {
    Write-Host "Destination missing - creating: $dstDir"
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
}

Write-Host "Installing VSCode config from $srcDir -> $dstDir" -ForegroundColor Cyan
Write-Host ""

# JSON-escaped form of $env:USERPROFILE (e.g. "C:\\Users\\foo")
$userProfileJson = $env:USERPROFILE.Replace('\', '\\')
$files = Get-ChildItem $srcDir -File
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

foreach ($f in $files) {
    $dstPath = Join-Path $dstDir $f.Name

    if (Test-Path $dstPath) {
        $bakPath = "$dstPath.$timestamp.bak"
        Copy-Item $dstPath $bakPath
        Write-Host "  Backed up: $($f.Name) -> $($f.Name).$timestamp.bak" -ForegroundColor Yellow
    }

    # For settings.json: substitute placeholder before writing
    if ($f.Name -eq "settings.json") {
        $content = [System.IO.File]::ReadAllText($f.FullName)
        $substituted = $content.Replace('__USERPROFILE__', $userProfileJson)
        [System.IO.File]::WriteAllText($dstPath, $substituted)
        Write-Host "  Installed: $($f.Name) (substituted __USERPROFILE__ -> $env:USERPROFILE)" -ForegroundColor Green
    } else {
        Copy-Item $f.FullName -Destination $dstPath -Force
        Write-Host "  Installed: $($f.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done. Reload VSCode (Ctrl+Shift+P -> Reload Window) to apply." -ForegroundColor Cyan
Write-Host ""
Write-Host "Reminder: download im-select.exe to ~\tools\ if Vim IME switching needed:" -ForegroundColor DarkGray
Write-Host "  https://github.com/daipeihust/im-select/raw/master/win/out/x64/im-select.exe" -ForegroundColor DarkGray

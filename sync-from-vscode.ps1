# sync-from-vscode.ps1 — pull current VSCode + Neovim config back into this repo
# Usage: cd ~/dotfiles && .\sync-from-vscode.ps1
#
# settings.json / init.lua: substitutes $env:USERPROFILE -> __USERPROFILE__ so
# the committed copy is machine-agnostic. install.ps1 reverses it.

$ErrorActionPreference = "Stop"

$repoDir = $PSScriptRoot
$userProfileJson = $env:USERPROFILE.Replace('\', '\\')

# Source map: repo subfolder -> live filesystem path
$sources = @(
    @{ repo = "vscode"; src = (Join-Path $env:APPDATA "Code\User") },
    @{ repo = "nvim";   src = (Join-Path $env:LOCALAPPDATA "nvim") }
)

function Get-StringHash([string]$text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    return [BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', ''
}

$totalChanged = @()
$totalUnchanged = @()
$totalMissing = @()

foreach ($s in $sources) {
    $srcDir = $s.src
    $dstDir = Join-Path $repoDir $s.repo

    if (-not (Test-Path $srcDir)) {
        Write-Host "  (skip) live missing: $srcDir" -ForegroundColor DarkGray
        continue
    }
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }

    Write-Host "Syncing $srcDir -> $dstDir" -ForegroundColor Cyan

    $tracked = Get-ChildItem $dstDir -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    if (-not $tracked) {
        Write-Host "  (skip) no tracked files in $dstDir; add files manually first." -ForegroundColor DarkGray
        continue
    }

    foreach ($name in $tracked) {
        $srcPath = Join-Path $srcDir $name
        $dstPath = Join-Path $dstDir $name

        if (-not (Test-Path $srcPath)) {
            $totalMissing += $name
            Write-Host "  MISSING in live: $name" -ForegroundColor Red
            continue
        }

        # Normalize USERPROFILE for files we know substitute placeholder
        if ($name -eq "settings.json" -or $name -eq "init.lua") {
            $liveContent = [System.IO.File]::ReadAllText($srcPath)
            $normalized = $liveContent.Replace($userProfileJson, '__USERPROFILE__')
            $repoContent = [System.IO.File]::ReadAllText($dstPath)

            if ((Get-StringHash $normalized) -ne (Get-StringHash $repoContent)) {
                [System.IO.File]::WriteAllText($dstPath, $normalized)
                $totalChanged += $name
                Write-Host "  Updated: $name (normalized USERPROFILE -> __USERPROFILE__)" -ForegroundColor Green
            } else {
                $totalUnchanged += $name
            }
        } else {
            $srcHash = (Get-FileHash $srcPath -Algorithm SHA256).Hash
            $dstHash = (Get-FileHash $dstPath -Algorithm SHA256).Hash
            if ($srcHash -ne $dstHash) {
                Copy-Item $srcPath -Destination $dstPath -Force
                $totalChanged += $name
                Write-Host "  Updated: $name" -ForegroundColor Green
            } else {
                $totalUnchanged += $name
            }
        }
    }
    Write-Host ""
}

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Changed:   $($totalChanged.Count)" -ForegroundColor Green
Write-Host "  Unchanged: $($totalUnchanged.Count)" -ForegroundColor DarkGray
Write-Host "  Missing:   $($totalMissing.Count)" -ForegroundColor $(if ($totalMissing.Count -gt 0) { 'Red' } else { 'DarkGray' })
Write-Host ""

if ($totalChanged.Count -gt 0) {
    Write-Host "Git diff preview:" -ForegroundColor Cyan
    Push-Location $repoDir
    try { git diff --stat } finally { Pop-Location }
    Write-Host ""
    Write-Host "Next:" -ForegroundColor Yellow
    Write-Host "  git add -A && git commit -m `"update: ...`"" -ForegroundColor DarkGray
    Write-Host "  git push" -ForegroundColor DarkGray
} else {
    Write-Host "Nothing to commit - repo already up to date." -ForegroundColor DarkGray
}

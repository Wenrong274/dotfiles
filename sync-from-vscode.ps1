# sync-from-vscode.ps1 — pull current VSCode user config back into this dotfiles repo
# Usage: cd ~/dotfiles && .\sync-from-vscode.ps1
#
# For settings.json: substitutes $env:USERPROFILE -> __USERPROFILE__ so the
# committed copy is machine-agnostic. install.ps1 reverses the substitution.

$ErrorActionPreference = "Stop"

$repoDir = $PSScriptRoot
$dstDir = Join-Path $repoDir "vscode"
$srcDir = Join-Path $env:APPDATA "Code\User"

if (-not (Test-Path $srcDir)) {
    Write-Error "VSCode user dir not found: $srcDir"
    exit 1
}

if (-not (Test-Path $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
}

Write-Host "Syncing $srcDir -> $dstDir" -ForegroundColor Cyan
Write-Host ""

# JSON-escaped form of $env:USERPROFILE (e.g. "C:\\Users\\foo")
$userProfileJson = $env:USERPROFILE.Replace('\', '\\')

$tracked = Get-ChildItem $dstDir -File | Select-Object -ExpandProperty Name

if ($tracked.Count -eq 0) {
    Write-Warning "No existing tracked files in $dstDir. Add files manually first."
    exit 1
}

$changed = @()
$unchanged = @()
$missing = @()

function Get-StringHash([string]$text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $hash = $sha.ComputeHash($bytes)
    return [BitConverter]::ToString($hash) -replace '-', ''
}

foreach ($name in $tracked) {
    $srcPath = Join-Path $srcDir $name
    $dstPath = Join-Path $dstDir $name

    if (-not (Test-Path $srcPath)) {
        $missing += $name
        Write-Host "  MISSING in VSCode: $name" -ForegroundColor Red
        continue
    }

    if ($name -eq "settings.json") {
        # Read live, substitute USERPROFILE -> placeholder, compare to repo copy
        $liveContent = [System.IO.File]::ReadAllText($srcPath)
        $normalized = $liveContent.Replace($userProfileJson, '__USERPROFILE__')
        $repoContent = [System.IO.File]::ReadAllText($dstPath)

        if ((Get-StringHash $normalized) -ne (Get-StringHash $repoContent)) {
            [System.IO.File]::WriteAllText($dstPath, $normalized)
            $changed += $name
            Write-Host "  Updated: $name (normalized USERPROFILE -> __USERPROFILE__)" -ForegroundColor Green
        } else {
            $unchanged += $name
        }
    } else {
        $srcHash = (Get-FileHash $srcPath -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash $dstPath -Algorithm SHA256).Hash

        if ($srcHash -ne $dstHash) {
            Copy-Item $srcPath -Destination $dstPath -Force
            $changed += $name
            Write-Host "  Updated: $name" -ForegroundColor Green
        } else {
            $unchanged += $name
        }
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Changed:   $($changed.Count)" -ForegroundColor Green
Write-Host "  Unchanged: $($unchanged.Count)" -ForegroundColor DarkGray
Write-Host "  Missing:   $($missing.Count)" -ForegroundColor $(if ($missing.Count -gt 0) { 'Red' } else { 'DarkGray' })
Write-Host ""

if ($changed.Count -gt 0) {
    Write-Host "Git diff preview:" -ForegroundColor Cyan
    Push-Location $repoDir
    try {
        git diff --stat
    } finally {
        Pop-Location
    }

    Write-Host ""
    Write-Host "Next:" -ForegroundColor Yellow
    Write-Host "  git add -A && git commit -m `"update: ...`"" -ForegroundColor DarkGray
    Write-Host "  git push" -ForegroundColor DarkGray
} else {
    Write-Host "Nothing to commit - repo already up to date." -ForegroundColor DarkGray
}

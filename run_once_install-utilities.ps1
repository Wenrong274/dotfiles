# run_once_install-utilities.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝一般通用工具（透過 winget）

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: Utilities ==========" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[error] winget not found." -ForegroundColor Red
    Write-Host "        Install 'App Installer' from Microsoft Store, then re-run." -ForegroundColor DarkGray
    Write-Host "        https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor DarkGray
    exit 1
}

# ------------------------------------------------------------
# 套件清單
# ------------------------------------------------------------
$packages = @(
    @{ id = "M2Team.NanaZip";          name = "NanaZip" },
    @{ id = "Snipaste.Snipaste";       name = "Snipaste" },
    @{ id = "Microsoft.PowerToys";     name = "PowerToys" },
    @{ id = "AnyAssociation.Anytype";  name = "Anytype" }
)

Write-Host "Installing utilities via winget..." -ForegroundColor Yellow
Write-Host ""

foreach ($pkg in $packages) {
    winget list --id $pkg.id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [skip] $($pkg.name) already installed" -ForegroundColor DarkGray
    } else {
        Write-Host "  Installing $($pkg.name)..." -ForegroundColor Green
        winget install --id $pkg.id --exact --source winget `
            --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [warn] $($pkg.name) install failed (exit $LASTEXITCODE)" -ForegroundColor Yellow
            $warnings.Add("$($pkg.name) 安裝失敗 — 請手動執行: winget install $($pkg.id)")
        }
    }
}

# ------------------------------------------------------------
# 警告彙整
# ------------------------------------------------------------
if ($warnings.Count -gt 0) {
    Write-Host "========== 警告 ==========" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  !! $w" -ForegroundColor Yellow }
    Write-Host ""
}

Write-Host ""
Write-Host "========== Utilities Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""

# run_once_install-dotnet.ps1
# chezmoi 在新機器第一次 apply 時自動執行一次
# 安裝 .NET SDK 10（LTS）

$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: .NET SDK ==========" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[error] winget not found." -ForegroundColor Red
    Write-Host "        Install 'App Installer' from Microsoft Store, then re-run." -ForegroundColor DarkGray
    Write-Host "        https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor DarkGray
    exit 1
}

# ------------------------------------------------------------
# .NET SDK 10 (LTS)
# ------------------------------------------------------------
winget list --id Microsoft.DotNet.SDK.10 --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] .NET SDK 10 already installed" -ForegroundColor DarkGray
} else {
    Write-Host "  Installing .NET SDK 10 (LTS)..." -ForegroundColor Green
    winget install --id Microsoft.DotNet.SDK.10 --exact --source winget `
        --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [error] .NET SDK 10 install failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    Write-Host "  .NET SDK 10 installed" -ForegroundColor Green
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

Write-Host "========== .NET SDK Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""

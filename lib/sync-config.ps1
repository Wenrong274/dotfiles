# lib\sync-config.ps1 — 共用設定檔同步函式
# Dot-source this file from install scripts:
#   . (Join-Path $PSScriptRoot "..\lib\sync-config.ps1")

function Sync-ConfigFile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Label,
        [switch]$DryRun
    )
    if (Test-Path $Destination) {
        $srcHash = (Get-FileHash -Path $Source -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -Path $Destination -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) {
            Write-Host "  [skip] $Label unchanged" -ForegroundColor DarkGray
            return
        }
        if ($DryRun) {
            Write-Host "  [dry-run] Would backup and overwrite $Label" -ForegroundColor Cyan
            return
        }
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item $Destination "$Destination.$timestamp.bak"
        Write-Host "  Backed up existing $Label" -ForegroundColor Yellow
    } elseif ($DryRun) {
        Write-Host "  [dry-run] Would install $Label -> $(Split-Path $Destination -Parent)" -ForegroundColor Cyan
        return
    }
    $destDir = Split-Path $Destination -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory $destDir -Force | Out-Null }
    Copy-Item $Source -Destination $Destination -Force
    Write-Host "  Installed: $Label -> $(Split-Path $Destination -Parent)" -ForegroundColor Green
}

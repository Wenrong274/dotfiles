# bootstrap.ps1 — 新機器一鍵設定所有工具
# Usage: git clone https://github.com/Wenrong274/dotfiles ~/dotfiles
#        cd ~/dotfiles && .\bootstrap.ps1
#        cd ~/dotfiles && .\bootstrap.ps1 -DryRun   # 預覽，不實際執行
#
# 前提：Windows 10/11 + winget 可用
# VSCode 設定由 Settings Sync 自動還原，不在此腳本範圍內

param(
    [switch]$DryRun  # 只顯示動作，不實際寫入檔案或安裝軟體
)

$ErrorActionPreference = "Stop"

$installers = @(
    "vscode-nvim\install.ps1",
    "notepadpp\install.ps1",
    "zed\install.ps1"
)

foreach ($rel in $installers) {
    $script = Join-Path $PSScriptRoot $rel
    if (Test-Path $script) {
        & $script @PSBoundParameters
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    } else {
        Write-Host "  [skip] $rel not found" -ForegroundColor DarkGray
    }
}

Write-Host "========== Bootstrap Complete ==========" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY-RUN] 以上為預覽，實際執行請移除 -DryRun 參數`n" -ForegroundColor Magenta }
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Reload VSCode -> sign in to Settings Sync to restore VSCode profiles" -ForegroundColor DarkGray
Write-Host ""

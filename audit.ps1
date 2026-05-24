# audit.ps1 — 本機 CI 流程，提交前執行確保品質
# 不被 chezmoi 部署（見 .chezmoiignore）

$ErrorActionPreference = "Stop"
# 確保 chezmoi 輸出與腳本中的中文能正確顯示
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = $PSScriptRoot
$failed = $false

Write-Host "========== Audit ==========" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. PowerShell syntax
# ------------------------------------------------------------
Write-Host "[1/6] PowerShell syntax..." -ForegroundColor Yellow
Get-ChildItem "$root\*.ps1" | Where-Object { $_.Name -ne "audit.ps1" } | ForEach-Object {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$errors) | Out-Null
    if ($errors) {
        Write-Host "  [error] $($_.Name)" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "    line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red }
        $script:failed = $true
    } else {
        Write-Host "  [ok] $($_.Name)" -ForegroundColor DarkGray
    }
}
# .ps1.tmpl: render via chezmoi execute-template, then check rendered PS syntax
Get-ChildItem "$root\*.ps1.tmpl" -ErrorAction SilentlyContinue | ForEach-Object {
    $tmplName = $_.Name
    $tmpPs1   = [System.IO.Path]::GetTempFileName() + ".ps1"
    try {
        (Get-Content $_.FullName -Raw) | chezmoi -S $root execute-template 2>$null |
            Out-File $tmpPs1 -Encoding UTF8
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [error] ${tmplName}: template render failed (exit $LASTEXITCODE)" -ForegroundColor Red
            $script:failed = $true
        } else {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($tmpPs1, [ref]$null, [ref]$errors) | Out-Null
            if ($errors) {
                Write-Host "  [error] $tmplName (rendered)" -ForegroundColor Red
                $errors | ForEach-Object { Write-Host "    line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red }
                $script:failed = $true
            } else {
                Write-Host "  [ok] $tmplName (rendered)" -ForegroundColor DarkGray
            }
        }
    } finally {
        if (Test-Path $tmpPs1) { Remove-Item $tmpPs1 -Force -ErrorAction SilentlyContinue }
    }
}
Write-Host ""

# ------------------------------------------------------------
# 2. Markdown lint
# ------------------------------------------------------------
Write-Host "[2/6] Markdown lint..." -ForegroundColor Yellow
Push-Location $root
# NPM_CONFIG_LOGLEVEL=error suppresses npm's "npm exec ..." console progress line
$env:npm_config_loglevel = 'error'
$mdOutput = npx --yes markdownlint-cli "**/*.md" --ignore node_modules 2>$null
$mdExit = $LASTEXITCODE
Remove-Item Env:\npm_config_loglevel -ErrorAction SilentlyContinue
# Only forward actual lint violations (format: path.md:line ...)
$mdOutput | Where-Object { "$_" -match '\.md:\d+' } | ForEach-Object { Write-Host "  $_" }
if ($mdExit -ne 0) {
    $failed = $true
} else {
    Write-Host "  [ok] all markdown files" -ForegroundColor DarkGray
}
Pop-Location
Write-Host ""

# ------------------------------------------------------------
# 3. chezmoi dry-run
# Note: output uses *target* names; run_once_install-X.ps1 → install-X.ps1 in diff headers.
# ------------------------------------------------------------
Write-Host "[3/6] chezmoi dry-run..." -ForegroundColor Yellow
Write-Host "  (target names shown: run_once_install-X.ps1 → install-X.ps1 in diff headers)" -ForegroundColor DarkGray
$dryRunOutput = chezmoi -S $root apply --dry-run --verbose --force 2>&1
# Show only file-level summary lines, not full diff hunks
$dryRunOutput | Where-Object {
    "$_" -match '^diff --git|^Run script|^chezmoi:'
} | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [error] chezmoi dry-run failed" -ForegroundColor Red
    $failed = $true
} else {
    # Detect merge-conflict markers and other anomaly keywords that should never appear
    $anomalyKeywords = @('<<<<<<<', '>>>>>>>', 'CONFLICT')
    $anomalies = $dryRunOutput | Where-Object {
        $line = "$_"
        $anomalyKeywords | Where-Object { $line.Contains($_) }
    }
    if ($anomalies) {
        Write-Host "  [error] dry-run output contains anomaly markers:" -ForegroundColor Red
        $anomalies | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        $failed = $true
    } else {
        Write-Host "  [ok] chezmoi dry-run passed" -ForegroundColor DarkGray
    }
}
Write-Host ""

# ------------------------------------------------------------
# 4. Consistency checks
# ------------------------------------------------------------
Write-Host "[4/6] Consistency checks..." -ForegroundColor Yellow
$consistencyFailed = $false

# Unified script inventory: .ps1 (SourceName = TargetName) + .ps1.tmpl (TargetName strips .tmpl)
# All subsequent checks iterate this inventory so .ps1.tmpl scripts get the same coverage as .ps1.
$scriptInventory = [System.Collections.Generic.List[PSCustomObject]]::new()
Get-ChildItem "$root\run_*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    $scriptInventory.Add([PSCustomObject]@{
        SourceName = $_.Name
        TargetName = $_.Name
        Content    = Get-Content $_.FullName -Raw
    })
}
Get-ChildItem "$root\run_*.ps1.tmpl" -ErrorAction SilentlyContinue | ForEach-Object {
    $scriptInventory.Add([PSCustomObject]@{
        SourceName = $_.Name
        TargetName = ($_.Name -replace '\.tmpl$', '')
        Content    = Get-Content $_.FullName -Raw
    })
}

# 4a. README 工具表 vs 實際 run_*.ps1 / run_*.ps1.tmpl 檔案
$readmeContent = Get-Content "$root\README.md" -Raw
$readmeScripts = [regex]::Matches($readmeContent, '`(run_[\w-]+\.ps1)`') |
    ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

foreach ($s in $scriptInventory) {
    if ($s.TargetName -notin $readmeScripts) {
        $label = if ($s.SourceName -ne $s.TargetName) { "$($s.SourceName) → $($s.TargetName)" } else { $s.SourceName }
        Write-Host "  [warn] $label not listed in README.md" -ForegroundColor Yellow
        $consistencyFailed = $true
    }
}
foreach ($r in $readmeScripts) {
    $found = $scriptInventory | Where-Object { $_.TargetName -eq $r }
    if (-not $found) {
        Write-Host "  [warn] README.md lists $r but no source script found" -ForegroundColor Yellow
        $consistencyFailed = $true
    }
}

# 4b. winget 腳本是否都有前置檢查（涵蓋 .ps1 與 .ps1.tmpl）
foreach ($s in $scriptInventory) {
    if (($s.Content -match 'winget install') -and (-not ($s.Content -match 'Get-Command winget'))) {
        Write-Host "  [warn] $($s.SourceName): uses winget but missing Get-Command winget check" -ForegroundColor Yellow
        $script:consistencyFailed = $true
    }
}

# 4c. npm 腳本是否包含完整 Node.js 前置區段（涵蓋 .ps1 與 .ps1.tmpl）
foreach ($s in $scriptInventory) {
    if ($s.Content -match 'npm install -g') {
        if (-not ($s.Content -match 'Get-Command npm')) {
            Write-Host "  [warn] $($s.SourceName): uses npm but missing Get-Command npm check" -ForegroundColor Yellow
            $script:consistencyFailed = $true
        }
        if (-not ($s.Content -match 'OpenJS\.NodeJS\.LTS')) {
            Write-Host "  [warn] $($s.SourceName): uses npm but missing Node.js fallback install" -ForegroundColor Yellow
            $script:consistencyFailed = $true
        }
    }
}

# 4d. Node.js bootstrap drift（claude-cli vs codex-cli 必須保持一致）
function Get-NodeBootstrapLine {
    param([string]$FilePath)
    $lines = Get-Content $FilePath
    $inBlock = $false
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        if (-not $inBlock -and $line -match '前置檢查：Node\.js') { $inBlock = $true; continue }
        if ($inBlock) {
            # Stop at the next section header after we've collected some lines
            if ($line -match '^# -{5,}' -and $result.Count -gt 0) { break }
            $result.Add($line)
        }
    }
    # Return only functional (non-comment, non-blank) lines, trimmed
    return $result |
        Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' } |
        ForEach-Object { $_.TrimEnd() }
}

$claudeBootstrap = Get-NodeBootstrapLine "$root\run_once_install-claude-cli.ps1"
$codexBootstrap  = Get-NodeBootstrapLine "$root\run_once_install-codex-cli.ps1"
if ($null -eq $claudeBootstrap -or $null -eq $codexBootstrap -or
    $claudeBootstrap.Count -eq 0 -or $codexBootstrap.Count -eq 0) {
    Write-Host "  [warn] could not extract Node.js bootstrap block from claude-cli or codex-cli" -ForegroundColor Yellow
    $consistencyFailed = $true
} elseif (($claudeBootstrap -join "`n") -ne ($codexBootstrap -join "`n")) {
    Write-Host "  [warn] Node.js bootstrap blocks differ between claude-cli and codex-cli (drift detected)" -ForegroundColor Yellow
    $consistencyFailed = $true
}

# 4e. Antigravity official installer scripts must verify agy exists（涵蓋 .ps1 與 .ps1.tmpl）
foreach ($s in $scriptInventory) {
    if (($s.Content -match 'antigravity\.google/cli/install\.ps1') -and
        (-not ($s.Content -match 'Get-Command\s+agy'))) {
        Write-Host "  [warn] $($s.SourceName): uses Antigravity installer but missing Get-Command agy check" -ForegroundColor Yellow
        $script:consistencyFailed = $true
    }
}

# 4f. Notepad++ installer must use ConvertFrom-Json + {{ include "notepadpp/plugins.json" }}
$nppEntry = $scriptInventory | Where-Object { $_.TargetName -match 'install-notepadpp' } | Select-Object -First 1
if ($nppEntry) {
    $nppContent = $nppEntry.Content
    if ($nppContent -match '\$plugins\s*=\s*@\(') {
        Write-Host "  [warn] $($nppEntry.SourceName): hardcoded `$plugins array — use ConvertFrom-Json from plugins.json" -ForegroundColor Yellow
        $script:consistencyFailed = $true
    }
    if (-not ($nppContent -match 'ConvertFrom-Json')) {
        Write-Host "  [warn] $($nppEntry.SourceName): missing ConvertFrom-Json — plugins.json not embedded" -ForegroundColor Yellow
        $script:consistencyFailed = $true
    }
    if (-not ($nppContent -match [regex]::Escape('include "notepadpp/plugins.json"'))) {
        Write-Host "  [warn] $($nppEntry.SourceName): missing {{ include `"notepadpp/plugins.json`" }} directive" -ForegroundColor Yellow
        $script:consistencyFailed = $true
    }
}

# 4g. AppData/Roaming/Notepad++/*.xml must not exist in source tree
$nppXmls = Get-ChildItem "$root\AppData\Roaming\Notepad++" -Filter "*.xml" -ErrorAction SilentlyContinue
if ($nppXmls) {
    foreach ($f in $nppXmls) {
        Write-Host "  [warn] Notepad++ runtime XML in source tree: AppData\Roaming\Notepad++\$($f.Name)" -ForegroundColor Yellow
    }
    $script:consistencyFailed = $true
}

if ($consistencyFailed) {
    $failed = $true
} else {
    Write-Host "  [ok] README sync, winget/npm/Antigravity guard (incl. .tmpl), Node.js drift, Notepad++ template + XML guard" -ForegroundColor DarkGray
}
Write-Host ""

# ------------------------------------------------------------
# 5. File encoding（所有 .ps1 / .md 必須是有效 UTF-8）
# ------------------------------------------------------------
Write-Host "[5/6] File encoding..." -ForegroundColor Yellow
$encodingFailed = $false
Get-ChildItem $root -Include "*.ps1", "*.ps1.tmpl", "*.md" -Recurse |
    Where-Object { $_.FullName -notmatch '\\.git\\' } |
    ForEach-Object {
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        # UTF-16 BOM (FF FE = LE, FE FF = BE) — forbidden; UTF-8 BOM (EF BB BF) is allowed
        if ($bytes.Length -ge 2 -and (
            ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or
            ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF))) {
            Write-Host "  [warn] $($_.Name): UTF-16 BOM detected (should be UTF-8)" -ForegroundColor Yellow
            $script:encodingFailed = $true
            return
        }
        # Strict UTF-8 validation
        try {
            $enc = New-Object System.Text.UTF8Encoding($false, $true)
            [void]$enc.GetString($bytes)
        } catch {
            Write-Host "  [warn] $($_.Name): invalid UTF-8 byte sequence" -ForegroundColor Yellow
            $script:encodingFailed = $true
        }
    }
if ($encodingFailed) { $failed = $true } else { Write-Host "  [ok] all .ps1/.ps1.tmpl/.md files are valid UTF-8" -ForegroundColor DarkGray }
Write-Host ""

# ------------------------------------------------------------
# 6. Pin values consistency（AGENTS.md Known Hardcoded Values ↔ scripts）
# ------------------------------------------------------------
Write-Host "[6/6] Pin values consistency..." -ForegroundColor Yellow
$pinFailed = $false

# Each entry: value must exist in the named file (relative to $root)
$pins = @(
    @{ value = "11ed9277fb3118b63b36cfca57c39fa4cc882512"; file = "run_once_install-neovim.ps1";    desc = "im-select.exe pinned commit" },
    @{ value = "E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6"; file = "run_once_install-neovim.ps1"; desc = "im-select.exe SHA256" },
    @{ value = "E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6"; file = "README.md";                   desc = "im-select.exe SHA256 in README" },
    @{ value = "v3.4.0";                 file = "run_once_install-fonts.ps1";           desc = "Nerd Fonts version" },
    @{ value = "Sans2.004";              file = "run_once_install-fonts.ps1";           desc = "Noto Sans TC release pin" },
    @{ value = "Wenrong274/rime-config"; file = "run_once_install-rime.ps1";            desc = "Rime config repo" },
    @{ value = "2.70.4";                 file = ".github\workflows\ci.yml";             desc = "chezmoi CI version pin" }
)

# AGENTS.md stores the SHA256 abbreviated, so check the prefix only
$agentsContent = Get-Content "$root\AGENTS.md" -Raw
$agentsPins = @(
    @{ value = "11ed9277fb3118b63b36cfca57c39fa4cc882512"; desc = "im-select.exe commit" },
    @{ value = "E66F0A6E";              desc = "im-select.exe SHA256 prefix" },
    @{ value = "v3.4.0";               desc = "Nerd Fonts version" },
    @{ value = "Sans2.004";            desc = "Noto Sans TC release" },
    @{ value = "Wenrong274/rime-config"; desc = "Rime config repo" },
    @{ value = "2.70.4";               desc = "chezmoi CI version" }
)

foreach ($pin in $pins) {
    $filePath = Join-Path $root $pin.file
    if (-not (Test-Path $filePath)) {
        Write-Host "  [warn] $($pin.file) not found — cannot verify: $($pin.desc)" -ForegroundColor Yellow
        $pinFailed = $true
    } elseif (-not (Get-Content $filePath -Raw).Contains($pin.value)) {
        Write-Host "  [warn] '$($pin.value)' missing in $($pin.file) ($($pin.desc))" -ForegroundColor Yellow
        $pinFailed = $true
    }
}
foreach ($pin in $agentsPins) {
    if (-not $agentsContent.Contains($pin.value)) {
        Write-Host "  [warn] '$($pin.value)' missing in AGENTS.md ($($pin.desc))" -ForegroundColor Yellow
        $pinFailed = $true
    }
}

if ($pinFailed) { $failed = $true } else { Write-Host "  [ok] all pin values present in scripts and AGENTS.md" -ForegroundColor DarkGray }
Write-Host ""

# ------------------------------------------------------------
# Result
# ------------------------------------------------------------
if ($failed) {
    Write-Host "========== FAILED — fix errors before committing ==========" -ForegroundColor Red
    exit 1
} else {
    Write-Host "========== All checks passed ==========" -ForegroundColor Green
}
Write-Host ""

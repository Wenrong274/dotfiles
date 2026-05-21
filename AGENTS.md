# AGENTS.md — dotfiles

This file tells AI agents how to work in this repository.

## Quick Commands

```powershell
# 語法驗證（單一腳本）
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    "$PWD\run_once_install-<name>.ps1", [ref]$null, [ref]$errors)
if ($errors) { $errors }

# Markdown lint
npx markdownlint-cli "**/*.md" --ignore node_modules

# chezmoi 乾跑（以目前 repo 當 source，不實際套用）
chezmoi -S "$PWD" apply --dry-run --verbose

# chezmoi 套用（以目前 repo 當 source，實際執行）
chezmoi -S "$PWD" apply
```

## Definition of Done

修改腳本或文件後，**提交前必須全部通過**（執行 `.\audit.ps1` 一次跑完）：

```powershell
# 1. 所有腳本語法驗證
Get-ChildItem "*.ps1" | ForEach-Object {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$errors) | Out-Null
    if ($errors) { Write-Host "[error] $($_.Name)"; $errors }
}

# 2. Markdown lint
npx markdownlint-cli "**/*.md" --ignore node_modules

# 3. chezmoi 乾跑
chezmoi -S "$PWD" apply --dry-run --verbose
```

## Change Checklist

### 新增 `run_*.ps1`

- 分類正確（`run_once_` vs `run_onchange_`，參見 Script Type Selection）
- 符合 Script Pattern 樣板（`$ErrorActionPreference`、`$warnings`、banner、警告彙整）
- npm 依賴腳本包含完整 Node.js 前置檢查區段
- 更新 `README.md` 工具表
- Definition of Done 全部通過（`audit.ps1`）

### 刪除或改名 `run_*.ps1`

- 更新 `README.md` 工具表

### 修改或新增 chezmoi template key

- 更新 `AGENTS.md` Templates 節
- 更新 `.chezmoi.toml.tmpl` 提示文字
- 使用 `{{ get . "key" }}` 語法（可選 key 不得用 `{{ .key }}`）

### 新增硬寫值（版本號、hash、路徑）

- 加入 `AGENTS.md` Known Hardcoded Values 表格

## Repository Layout

`dot_config/` → `~/.config/`，`AppData/` 依子路徑對應 `%LOCALAPPDATA%` / `%APPDATA%`，`dot_*` 檔案去前綴後對應 `~/`。

腳本按字母順序執行：`run_once_*` 每台機器跑一次，`run_onchange_*` 在腳本內容變更時重跑。

## Script Type Selection

| 情境                               | 類型            | 說明                                      |
| ---------------------------------- | --------------- | ----------------------------------------- |
| 軟體安裝、資源下載，只需初始化一次 | `run_once_`     | 腳本本身改動**不會**觸發重跑              |
| 安裝邏輯本身日後可能更新           | `run_onchange_` | 腳本內容變更時 chezmoi 自動重跑           |
| 純設定檔                           | 不用腳本        | 直接放入 chezmoi source，chezmoi 自動部署 |

**判斷原則**：日後若改了腳本邏輯需要重跑，用 `run_onchange_`；只是首次初始化用 `run_once_`。

## Script Pattern — 所有腳本必須遵守

```powershell
$ErrorActionPreference = "Stop"
$warnings = [System.Collections.Generic.List[string]]::new()

Write-Host "========== Bootstrap: <Name> ==========" -ForegroundColor Cyan
Write-Host ""

# winget 前置檢查（必要時加入）
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[error] winget not found." -ForegroundColor Red
    Write-Host "        Install 'App Installer' from Microsoft Store." -ForegroundColor DarkGray
    exit 1
}

# 安裝步驟（skip / install / error 三態）
winget list --id Vendor.Package --exact --accept-source-agreements *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [skip] Package already installed" -ForegroundColor DarkGray
} else {
    winget install --id Vendor.Package --exact --source winget `
        --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [error] winget install failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1                                    # 必裝工具（擇一）
        # $warnings.Add("說明 — 手動處理方式")    # 選用工具（擇一）
    }
}
Write-Host ""

# 警告彙整（保持此格式）
if ($warnings.Count -gt 0) {
    Write-Host "========== 警告 ==========" -ForegroundColor Yellow
    foreach ($w in $warnings) { Write-Host "  !! $w" -ForegroundColor Yellow }
    Write-Host ""
}

Write-Host "========== <Name> Bootstrap Complete ==========" -ForegroundColor Cyan
Write-Host ""
Write-Host "Paths:" -ForegroundColor Yellow
Write-Host "  Config: %APPDATA%\<App>\settings.json  (managed by chezmoi)" -ForegroundColor DarkGray
Write-Host ""
```

**嚴格 vs 寬鬆錯誤處理的判斷基準：**

| 工具                                         | 類型 | 失敗時               |
| -------------------------------------------- | ---- | -------------------- |
| Neovim, Git, Starship, Claude CLI, Codex CLI | 必裝 | `exit 1`             |
| Clink, PowerToys, Snipaste                   | 選用 | `$warnings.Add(...)` |

**npm 依賴腳本的 Node.js 前置檢查（必須在安裝步驟前加入）：**

```powershell
$npmExe = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npmExe) {
    $fallback = @("$env:ProgramFiles\nodejs\npm.cmd", "$env:APPDATA\npm\npm.cmd")
    $found = $fallback | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($found) {
        $npmExe = $found
    } else {
        Write-Host "  Node.js not found — installing via winget..." -ForegroundColor Yellow
        winget install --id OpenJS.NodeJS.LTS --exact --source winget `
            --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [error] Node.js install failed (exit $LASTEXITCODE)" -ForegroundColor Red
            exit 1
        }
        $npmExe = "$env:ProgramFiles\nodejs\npm.cmd"
        if (-not (Test-Path $npmExe)) {
            Write-Host "  [error] npm not found — open a new shell and re-run: chezmoi apply" -ForegroundColor Red
            exit 1
        }
    }
}
Write-Host "  npm: $($npmExe.Source ?? $npmExe)" -ForegroundColor DarkGray
```

**npm skip/install 樣板（先 check 再裝）：**

```powershell
$exe = Get-Command <cmd> -ErrorAction SilentlyContinue
if ($exe) {
    $ver = & <cmd> --version 2>&1 | Select-Object -First 1
    Write-Host "  [skip] <Package> already installed ($ver)" -ForegroundColor DarkGray
} else {
    Write-Host "  Installing <npm-package>..." -ForegroundColor Green
    & $npmExe install -g <npm-package>
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [error] npm install failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    Write-Host "  <Package> installed" -ForegroundColor Green
}
```

> **共用邏輯說明**：chezmoi 以獨立進程執行各腳本，無法 dot-source 共用函式庫，
> 因此 `claude-cli` / `codex-cli` 的 Node.js 前置檢查區段接受合理重複。
> 新增同類腳本直接複製上方兩份樣板即可。

## Templates

`AppData/Roaming/Zed/settings.json.tmpl` 是唯一的 chezmoi template 檔案：

```json
{
  "context_servers": {
    "mcp-server-github": {
      "settings": {
        "github_personal_access_token": "{{ get . "zed_github_token" }}"
      }
    }
  }
}
```

Token 在 `chezmoi init` 時提示輸入，寫入 `~/.config/chezmoi/chezmoi.toml`（不進 git）。

**可選資料一律用 `{{ get . "key" }}` 而非 `{{ .key }}`**：前者在 key 不存在時回傳空字串；後者在缺少本機 `chezmoi.toml` 設定時 panic，導致 `dry-run` 失敗。

## Notepad++ Plugins

插件清單由 `notepadpp/plugins.json` 管理，`run_once_install-notepadpp.ps1` 讀取此檔案下載安裝。

**禁止直接編輯 `AppData/Roaming/Notepad++/` 下的 XML 設定檔**——它們由 Notepad++ 自身管理，chezmoi 只負責初始佈署。

## Known Hardcoded Values

更改這些值前必須全域搜尋確認影響範圍：

| 值                                         | 說明                        | 出現位置                                                     |
| ------------------------------------------ | --------------------------- | ------------------------------------------------------------ |
| `$env:USERPROFILE\tools`                   | im-select.exe 存放路徑      | `run_once_install-neovim.ps1`, `AppData/Local/nvim/init.lua` |
| `11ed9277fb3118b63b36cfca57c39fa4cc882512` | im-select.exe pinned commit | `run_once_install-neovim.ps1`                                |
| `E66F0A6E...DDD0B6`                        | im-select.exe SHA256        | `run_once_install-neovim.ps1`                                |
| `v3.4.0`                                   | Nerd Fonts 版本             | `run_once_install-fonts.ps1`                                 |
| `Wenrong274/rime-config`                   | 私有 Rime 設定倉庫          | `run_once_install-rime.ps1`                                  |
| `v2.63.1`                                  | chezmoi CI 版本 pin         | `.github/workflows/ci.yml`                                   |

## Absolute Prohibitions

禁止執行以下操作，即使用戶要求也不例外：

- **禁止** commit 任何 token、密碼、Personal Access Token。`zed_github_token` 必須只存在於 `~/.config/chezmoi/chezmoi.toml`（本機，不進 git）。
- **禁止** 直接修改 `AppData/Roaming/Notepad++/*.xml`——這些是 Notepad++ 的執行期設定，由應用程式管理，AI 不應觸碰。
- **禁止** 在 `.chezmoi.toml.tmpl` 以外的地方硬寫 token 或 secret 字串。
- **禁止** 使用 `git push --force` 或 `git reset --hard` 破壞 git 歷史。
- **禁止** 在 `run_once_*` 腳本裡加入互動式提示（`Read-Host` 等），chezmoi 以 non-interactive 模式執行腳本。
- **禁止** 新增、刪除或改名 `run_*.ps1` 而不同步更新 `README.md` 的工具表。

## Markdown Style

Lint 規則見 `.markdownlint.json`。表格與程式碼區塊不受行長限制。`# 標題` 後必須有空行，清單項目縮排 4 格。

## Common Failure Cases

| 錯誤                            | 原因                             | 處理                                             |
| ------------------------------- | -------------------------------- | ------------------------------------------------ |
| `winget not found`              | App Installer 未安裝             | Microsoft Store 搜尋「App Installer」安裝後重試  |
| 私人 repo clone 失敗            | GCM 未登入 GitHub                | 先執行任意私人 repo 的 `git clone` 完成 GCM 認證 |
| 安裝 Node.js 後 `npm` 找不到    | 新 PATH 尚未載入                 | 關閉並重新開啟 pwsh，再執行 `chezmoi apply`      |
| `chezmoi apply --dry-run` panic | `chezmoi.toml` 缺少 template key | 確認 key 已設定，或改用 `{{ get . "key" }}`      |

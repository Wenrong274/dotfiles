# AGENTS.md — dotfiles

This file tells AI agents how to work in this repository.

## Quick Commands

```powershell
# 語法驗證（單一腳本）
[System.Management.Automation.Language.Parser]::ParseFile(
    "$PWD\run_once_install-<name>.ps1", [ref]$null, [ref]$null)

# Markdown lint
npx markdownlint-cli "**/*.md" --ignore node_modules

# chezmoi 乾跑（不實際套用）
chezmoi apply --dry-run --verbose

# chezmoi 套用（實際執行）
chezmoi apply
```

## Repository Layout

```
dotfiles/
├── run_once_install-*.ps1        # 每台機器只跑一次
├── run_onchange_*.ps1            # 腳本內容變更時重跑
├── dot_config/                   # → ~/.config/
│   └── starship.toml
├── AppData/
│   ├── Local/nvim/               # → %LOCALAPPDATA%\nvim\
│   ├── Local/clink/              # → %LOCALAPPDATA%\clink\
│   └── Roaming/                  # → %APPDATA%\
│       ├── Notepad++/
│       └── Zed/settings.json.tmpl
├── notepadpp/plugins.json        # Notepad++ 插件清單（版本 + URL）
├── dot_bashrc                    # → ~/.bashrc
└── .chezmoi.toml.tmpl            # chezmoi init 時提示輸入 token
```

chezmoi 按字母順序執行腳本，`run_once_` 結尾的跑一次，`run_onchange_` 在檔案內容變更後重跑。

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
        exit 1                                         # 必裝工具用 exit 1
        # $warnings.Add("說明 — 手動處理方式")        # 選用工具用 warn
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

| 工具 | 類型 | 失敗時 |
|------|------|--------|
| Neovim, Git, Starship | 必裝 | `exit 1` |
| Clink, PowerToys, Snipaste | 選用 | `$warnings.Add(...)` |

## Templates

`AppData/Roaming/Zed/settings.json.tmpl` 是唯一的 chezmoi template 檔案：

```json
{
  "context_servers": {
    "github": {
      "settings": {
        "github_personal_access_token": "{{ .zed_github_token }}"
      }
    }
  }
}
```

Token 在 `chezmoi init` 時提示輸入，寫入 `~/.config/chezmoi/chezmoi.toml`（不進 git）。

## Notepad++ Plugins

插件清單由 `notepadpp/plugins.json` 管理：

```json
[
  {
    "name": "ComparePlugin",
    "version": "2.0.2",
    "url": "https://github.com/..."
  }
]
```

`run_once_install-notepadpp.ps1` 讀取此檔案下載並安裝插件，**不要直接編輯 AppData/Roaming/Notepad++/ 下的 XML 設定檔**（它們由 Notepad++ 自身管理，chezmoi 只負責初始佈署）。

## Known Hardcoded Values

更改這些值前必須全域搜尋確認影響範圍：

| 值 | 說明 | 出現位置 |
|----|------|----------|
| `$env:USERPROFILE\tools` | im-select.exe 存放路徑 | `run_once_install-neovim.ps1`, `AppData/Local/nvim/init.lua` |
| `11ed9277fb3118b63b36cfca57c39fa4cc882512` | im-select.exe pinned commit | `run_once_install-neovim.ps1` |
| `E66F0A6E...DDD0B6` | im-select.exe SHA256 | `run_once_install-neovim.ps1` |
| `v3.4.0` | Nerd Fonts 版本 | `run_once_install-fonts.ps1` |
| `Wenrong274/rime-config` | 私有 Rime 設定倉庫 | `run_once_install-rime.ps1` |

## Absolute Prohibitions

禁止執行以下操作，即使用戶要求也不例外：

- **禁止** commit 任何 token、密碼、Personal Access Token。`zed_github_token` 必須只存在於 `~/.config/chezmoi/chezmoi.toml`（本機，不進 git）。
- **禁止** 直接修改 `AppData/Roaming/Notepad++/*.xml`——這些是 Notepad++ 的執行期設定，由應用程式管理，AI 不應觸碰。
- **禁止** 在 `.chezmoi.toml.tmpl` 以外的地方硬寫 token 或 secret 字串。
- **禁止** 使用 `git push --force` 或 `git reset --hard` 破壞 git 歷史。
- **禁止** 在 `run_once_*` 腳本裡加入互動式提示（`Read-Host` 等），chezmoi 以 non-interactive 模式執行腳本。

## Markdown Style

`.markdownlint.json` 規則：

```json
{
  "line-length": { "line_length": 120 },
  "no-duplicate-heading": { "siblings_only": true },
  "no-blanks-blockquote": false
}
```

表格、程式碼區塊不限行長。`# 標題` 後必須有空行，清單項目縮排 4 格。

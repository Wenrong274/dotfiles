# Zed 設定說明

> 個人化設定備份，對應 `zed/settings.json`。

---

## 設定概覽

設定檔位置：`%APPDATA%\Zed\settings.json`

| 項目                           | 設定值                      | 說明                          |
| ------------------------------ | --------------------------- | ----------------------------- |
| `vim_mode`                     | `true`                      | 啟用內建 Vim 模式             |
| `base_keymap`                  | `VSCode`                    | 快捷鍵基礎採用 VSCode 配置    |
| `buffer_font_family`           | JetBrains Mono              | 編輯區主要字型                |
| `buffer_font_fallbacks`        | Noto Sans TC, FiraCode      | 中文及備用字型                |
| `terminal.font_family`         | Hack Nerd Font              | 內建終端字型                  |
| `theme`                        | Catppuccin Macchiato (dark) | 深色主題                      |
| `icon_theme`                   | Catppuccin Mocha            | 圖示主題                      |
| `relative_line_numbers`        | `enabled`                   | 相對行號（配合 Vim 跳行）     |
| `mouse_wheel_zoom`             | `true`                      | 滾輪縮放字型大小              |
| `vertical_scroll_margin`       | `5.0`                       | 捲動時保留上下 5 行可見       |
| `preview_tabs`                 | `false`                     | 停用預覽頁籤，單點即固定開啟  |
| `sticky_scroll`                | `true`                      | 捲動時固定顯示當前 scope 標頭 |
| `minimap`                      | `auto`                      | 自動顯示 minimap              |
| `semantic_tokens`              | `full`                      | 完整語意 token 上色           |
| `ensure_final_newline_on_save` | `true`                      | 儲存時自動補最後換行          |
| `cli_default_open_behavior`    | `existing_window`           | `zed .` 優先用現有視窗開啟    |

---

## Vim 模式

Zed 內建 Vim 模式（**非嵌入 Neovim**），以 `base_keymap: "VSCode"` 為基礎。

支援的功能：

- Normal / Insert / Visual / Command-line 模式切換
- `hjkl`、`w/b/e`、`0/$`、`gg/G` 等基礎移動
- `d/c/y` + 文字物件（`iw`、`i"`、`i(` 等）
- `/` 搜尋、`n/N`、`*`
- `:` command-line（基本 ex 指令）

**與 vscode-neovim 的差異**：

|                    | Zed Vim     | vscode-neovim         |
| ------------------ | ----------- | --------------------- |
| 實作方式           | 內建重寫    | 真正的 Neovim process |
| Lua 插件           | ❌          | ✅（lazy.nvim 等）    |
| im-select IME 切換 | ❌          | ✅                    |
| 完整度             | 基本操作 OK | 接近完整 Vim          |

> 需要完整 Vim 體驗時，使用 VSCode + vscode-neovim。

---

## MCP 整合

設定中啟用了 `mcp-server-github`，讓 Zed 的 Agent Panel 可存取 GitHub：

```json
"context_servers": {
  "mcp-server-github": {
    "enabled": true,
    "settings": {
      "github_personal_access_token": "YOUR_TOKEN_HERE"
    }
  }
}
```

> **新機器還原後必須手動填入 token**。`install.ps1` 會在 settings.json 仍含 placeholder 時發出警告。

### 取得 GitHub Personal Access Token

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. 建議最小權限：`Contents: Read`、`Issues: Read`、`Pull requests: Read`
3. 產生後填入 `%APPDATA%\Zed\settings.json` 對應欄位

---

## Agent Servers

| Agent                | 說明                                  |
| -------------------- | ------------------------------------- |
| `claude-acp`         | Anthropic Claude（透過 Zed registry） |
| `github-copilot-cli` | GitHub Copilot CLI                    |

---

## 日常維護

### 同步設定變更回 repo

在 Zed 內調整設定後（`Ctrl+Shift+P` → `zed: open settings`），把最新設定回拷：

```powershell
cd $env:USERPROFILE\dotfiles
Copy-Item "$env:APPDATA\Zed\settings.json" .\zed\settings.json
git add zed/settings.json
git commit -m "update: zed settings"
git push
```

> **注意**：回拷前確認 `github_personal_access_token` 已替換為 placeholder `"GITHUB_PERSONAL_ACCESS_TOKEN"`，避免 token 提交到 repo。

### 重新安裝（新機器）

```powershell
cd $env:USERPROFILE\dotfiles
.\zed\install.ps1
# 安裝完成後手動填入 github_personal_access_token
```

---

最後更新：2026-05-19

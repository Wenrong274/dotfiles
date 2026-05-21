# wenrong's dotfiles

個人 Windows 開發環境設定，使用 **[chezmoi](https://www.chezmoi.io/)** 管理，支援多機同步。

## 新機器一鍵還原

> Notepad++ 插件與 Chocolatey 需要**系統管理員**權限，建議以 Admin 身分執行。

```powershell
# 1. 安裝 chezmoi 與 PowerShell 7
winget install twpayne.chezmoi Microsoft.PowerShell

# 2. 重新開啟 pwsh（PowerShell 7 終端）再執行以下步驟

# 3. 初始化並套用（全部自動完成）
chezmoi init --apply https://github.com/Wenrong274/dotfiles
```

> ℹ️ 步驟 3 必須在 **pwsh（PowerShell 7）** 中執行，chezmoi 才能以 PS 7 直譯所有腳本。

執行後會自動安裝所有工具、部署設定檔，過程中可能需要：

```
Zed GitHub Personal Access Token (留空跳過): ▌
```

> ⚠️ `rime-config` 為私人 repo，若 Git Credential Manager 尚未登入 GitHub，clone 會略過並顯示手動指令。建議 `chezmoi apply` 前先確認 `git clone` 任意私人 repo 可正常運作。

VSCode 設定由 **Settings Sync** 自動還原，登入帳號即可。

---

## 自動安裝的工具

| 腳本 | 安裝內容 | 備註 |
|---|---|---|
| `run_once_install-chocolatey.ps1` | Chocolatey、ripgrep、bat | 需要 Admin |
| `run_once_install-claude-cli.ps1` | Claude Code CLI | 需要 Node.js |
| `run_once_install-fonts.ps1` | Hack NF、JetBrains Mono NF、FiraCode NF、Noto Sans TC | |
| `run_once_install-neovim.ps1` | Git、Neovim、PowerShell 7、im-select.exe | |
| `run_once_install-notepadpp.ps1` | Notepad++、插件 | 插件需要 Admin |
| `run_once_install-rime.ps1` | Weasel（小狼毫）、rime-config | |
| `run_once_install-starship.ps1` | Starship、Clink | |
| `run_once_install-utilities.ps1` | NanaZip、Snipaste、PowerToys、Anytype | |
| `run_once_install-vscode.ps1` | Visual Studio Code | |
| `run_onchange_install-zed.ps1` | Node.js LTS、Zed | |
| `run_onchange_setup-pwsh-starship.ps1` | Starship 加入 pwsh profile | |

---

## 管理的設定檔

```text
dotfiles/
├── AppData/
│   ├── Local/
│   │   ├── clink/
│   │   │   └── starship.lua          # Starship CMD 整合（Clink）
│   │   └── nvim/
│   │       ├── init.lua              # Neovim 設定（vscode-neovim）
│   │       └── lazy-lock.json        # Plugin 版本鎖
│   └── Roaming/
│       ├── Notepad++/                # config.xml / shortcuts.xml / stylers.xml / langs.xml / contextMenu.xml
│       └── Zed/
│           └── settings.json.tmpl   # Zed 設定（GitHub token 由 chezmoi template 填入）
├── dot_config/
│   └── starship.toml                 # Starship prompt 設定
├── dot_bashrc                        # Bash 設定（Git Bash / WSL）
├── .chezmoi.toml.tmpl               # chezmoi 機器設定模板（進 git）；產生的 chezmoi.toml 不進 git
├── notepadpp/
│   └── plugins.json                  # Notepad++ 插件清單
└── vscode-nvim/docs/                 # Vim 使用文件（僅供參考，不部署）
```

---

## 日常維護

### 同步設定到 repo

在任意機器修改設定後：

```powershell
chezmoi re-add        # 把系統上的設定同步回 source
chezmoi diff          # 確認變更內容

cd (chezmoi source-path)
git add .
git commit -m "update: <what changed>"
git push
```

### 在另一台機器拉取最新設定

```powershell
chezmoi update        # pull + apply，一條命令搞定
```

### Neovim plugin 更新

```powershell
# 1. 在 nvim 內更新
#    升級全部：  :Lazy update
#    還原 lock： :Lazy restore

# 2. 同步 lock 檔回 repo
chezmoi re-add "$env:LOCALAPPDATA\nvim\lazy-lock.json"

cd (chezmoi source-path)
git add AppData/Local/nvim/lazy-lock.json
git commit -m "chore: bump plugin lock"
git push
```

### Notepad++ 插件版本更新

編輯 `notepadpp/plugins.json` 的 `version` 和 `url`，commit 後在目標機器執行 `chezmoi update`。

### GitHub token 更新

token 存在本機 `~/.config/chezmoi/chezmoi.toml`，不進 git。修改方式：

```powershell
chezmoi edit-config   # 編輯 token
chezmoi apply         # 重新產生 Zed settings.json
```

---

## im-select.exe

Neovim 在 Normal / Insert 模式自動切換中英文輸入法用。`run_once_install-neovim.ps1` 會自動下載並驗證 SHA256。

手動下載：
- URL: <https://raw.githubusercontent.com/daipeihust/im-select/11ed9277fb3118b63b36cfca57c39fa4cc882512/win/out/x64/im-select.exe>
- SHA256: `E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6`

```powershell
# 驗證（True = 正確）
(Get-FileHash im-select.exe -Algorithm SHA256).Hash -eq `
    "E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6"
```
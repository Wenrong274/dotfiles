# wenrong's dotfiles

個人 VSCode + Vim 配置備份，跨機還原用。

## 結構

```
dotfiles/
├── vscode/
│   ├── settings.json           # VSCode 主設定（含 VSCodeVim 完整映射）
│   ├── keybindings.json        # VSCode 全域快捷鍵
│   ├── vim-cheatsheet.md       # Vim 個人映射速查表
│   ├── vim-guide.md            # Vim 完整使用文件
│   └── vim-test-checklist.md   # 設定驗證清單
├── install.ps1                 # 一鍵還原腳本
├── .gitignore
└── README.md
```

## 在新機器上還原

```powershell
# 1. clone 到任意位置
git clone <this-repo-url> "$env:USERPROFILE\dotfiles"

# 2. 跑安裝腳本
cd "$env:USERPROFILE\dotfiles"
.\install.ps1
```

`install.ps1` 會把 `vscode\` 內所有檔案複製到 `%APPDATA%\Code\User\`，覆蓋前會自動備份原檔到 `*.bak`。

## 額外依賴

### im-select.exe（Vim 自動切換輸入法用）

不放在 repo 內，請手動下載到 `%USERPROFILE%\tools\im-select.exe`：

- 官方下載：<https://github.com/daipeihust/im-select/raw/master/win/out/x64/im-select.exe>
- 用途：搭配 `vim.autoSwitchInputMethod` 在 Insert/Normal 模式自動切換中英文輸入法

### VSCode 擴充清單

設定假設以下擴充已裝（不一定全裝，沒裝就略過該段功能）：

| 擴充 | 用途 |
|---|---|
| `vscodevim.vim` | **必要** Vim 模擬 |
| `pkief.material-icon-theme` | 圖示主題 |
| `zhuangtongfa.material-theme` | One Dark Pro |
| `ms-dotnettools.csharp` | C# 語言支援 |
| `esbenp.prettier-vscode` | JS/TS/CSS formatter |
| `davidanson.vscode-markdownlint` | Markdown lint |
| `streetsidesoftware.code-spell-checker` | 拼字檢查 |

## 同步策略

| 方向 | 腳本 | 何時用 |
|---|---|---|
| **VSCode → repo**（備份） | `.\sync-from-vscode.ps1` | 改完 VSCode 設定，要備份到 git |
| **repo → VSCode**（還原） | `.\install.ps1` | 換機 / 重灌後初次設定 |

### 日常維護流程

```powershell
cd $env:USERPROFILE\dotfiles
.\sync-from-vscode.ps1            # 比對 hash，只複製有改動的檔
git add -A
git commit -m "update: <what changed>"
git push
```

`sync-from-vscode.ps1` 會：

- SHA256 比對來源與目的，**只動有變的檔**
- 列出 changed / unchanged / missing 摘要
- 跑 `git diff --stat` 預覽變更

VSCode 內建 Settings Sync 也可用，但會塞進 GitHub Gist 不直觀，這套腳本流程更可控。

## 隱私

此 repo 應設為 **private**。內含：

- 內部 IP（`security.allowedUNCHosts`）
- Sync gist ID
- GCP project ID（Gemini Code Assist）

不含密碼或 API key。

# wenrong's dotfiles

個人 Neovim 配置備份，跨機還原用。VSCode 設定由 **Settings Sync** 管理。

## 結構

```text
dotfiles/
├── nvim/
│   └── init.lua        # Neovim 設定（vscode-neovim 主要 / standalone fallback）
├── bootstrap.ps1       # 新機器一鍵安裝
├── .gitignore
└── README.md
```

## 在新機器上還原

```powershell
# 1. clone 到任意位置
git clone <this-repo-url> "$env:USERPROFILE\dotfiles"

# 2. 跑 bootstrap
cd "$env:USERPROFILE\dotfiles"
.\bootstrap.ps1
```

`bootstrap.ps1` 會依序：

1. 用 winget 安裝 Neovim、PowerShell 7
2. 下載 `im-select.exe` 到 `%USERPROFILE%\tools\`
3. 複製 `nvim/init.lua` 到 `%LOCALAPPDATA%\nvim\`

VSCode Profile 設定（settings、keybindings、extensions）由 **Settings Sync** 自動還原，登入帳號即可。

## im-select.exe

用途：`nvim/init.lua` 透過 `InsertLeave`/`InsertEnter` autocmd 在 Normal/Insert 模式自動切換中英文輸入法。

`bootstrap.ps1` 會自動下載。手動下載：<https://github.com/daipeihust/im-select/raw/master/win/out/x64/im-select.exe>

## 日常維護

修改 `nvim/init.lua` 後：

```powershell
cd $env:USERPROFILE\dotfiles
git add nvim/init.lua
git commit -m "update: <what changed>"
git push
```

# wenrong's dotfiles

個人 Neovim 配置備份，跨機還原用。VSCode 設定由 **Settings Sync** 管理。

## 結構

```text
dotfiles/
├── nvim/
│   ├── init.lua        # Neovim 設定（vscode-neovim 主要 / standalone fallback）
│   └── lazy-lock.json  # plugin 版本鎖（跨機一致）
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
3. 複製 `nvim/init.lua` + `nvim/lazy-lock.json` 到 `%LOCALAPPDATA%\nvim\`

首次啟動 nvim 後執行 `:Lazy restore`，可將 plugin 鎖定到 `lazy-lock.json` 紀錄的 commit。

VSCode Profile 設定（settings、keybindings、extensions）由 **Settings Sync** 自動還原，登入帳號即可。

## im-select.exe

用途：`nvim/init.lua` 透過 `InsertLeave`/`InsertEnter` autocmd 在 Normal/Insert 模式自動切換中英文輸入法。

`bootstrap.ps1` 會自動下載並驗證 SHA256（pinned 到固定 commit）。

手動下載（如需）：

- URL: <https://raw.githubusercontent.com/daipeihust/im-select/11ed9277fb3118b63b36cfca57c39fa4cc882512/win/out/x64/im-select.exe>
- Expected SHA256: `E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6`
- 驗證：`(Get-FileHash im-select.exe -Algorithm SHA256).Hash`

## 日常維護

修改 `nvim/init.lua` 後：

```powershell
cd $env:USERPROFILE\dotfiles
git add nvim/init.lua
git commit -m "update: <what changed>"
git push
```

新增/升級 plugin 後，把 lock 檔一起 commit，跨機才會一致：

```powershell
Copy-Item "$env:LOCALAPPDATA\nvim\lazy-lock.json" .\nvim\lazy-lock.json
git add nvim/lazy-lock.json
git commit -m "chore: bump plugin lock"
```

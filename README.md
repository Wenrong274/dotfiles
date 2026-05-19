# wenrong's dotfiles

個人開發環境設定備份，跨機還原用。**僅支援 Windows 10/11**（bootstrap 依賴 winget + PowerShell）。VSCode 設定由 **Settings Sync** 管理。

## 結構

```text
dotfiles/
├── vscode-nvim/
│   ├── init.lua        # Neovim 設定（專用於 vscode-neovim 擴充套件）
│   ├── lazy-lock.json  # plugin 版本鎖（跨機一致）
│   ├── install.ps1     # vscode-nvim 安裝腳本
│   └── docs/           # vim 使用文件（4 份，配合 init.lua 的個人映射）
│       ├── vim-onboarding.md     # 4 週上手路徑
│       ├── vim-guide.md          # 概念教學 + 為什麼這樣設
│       ├── vim-cheatsheet.md     # 操作速查表
│       └── vim-test-checklist.md # 50 項設定驗證清單
├── notepadpp/
│   ├── install.ps1     # Notepad++ 安裝腳本
│   ├── plugins.json
│   └── config/         # config.xml / shortcuts.xml / stylers.xml / langs.xml / contextMenu.xml
├── zed/
│   ├── install.ps1     # Zed 安裝腳本
│   └── settings.json   # Zed 設定（注意：MCP token 需手動填入）
├── lib/
│   └── sync-config.ps1 # 共用 Sync-ConfigFile 函式（各 install.ps1 dot-source）
├── bootstrap.ps1       # 新機器一鍵安裝（依序呼叫各工具的 install.ps1）
├── .gitattributes      # 跨平台換行符規範
├── .gitignore
├── LICENSE
└── README.md
```

> `vscode-nvim/docs/` 只是參考文件，不會被 `install.ps1` 部署。直接在 dotfiles 內閱讀或編輯即可。

## 在新機器上還原

> **注意**：Notepad++ plugins 安裝需要**系統管理員**權限。建議以系統管理員身分執行 PowerShell 後再跑 bootstrap。

```powershell
# 1. clone 到任意位置
git clone https://github.com/Wenrong274/dotfiles "$env:USERPROFILE\dotfiles"

# 2. 跑 bootstrap（建議以系統管理員身分執行）
cd "$env:USERPROFILE\dotfiles"
.\bootstrap.ps1
```

`bootstrap.ps1` 依序呼叫各工具的 `install.ps1`：

**vscode-nvim/install.ps1** 會依序：

1. 用 winget 安裝 Neovim、PowerShell 7
2. 下載 `im-select.exe` 到 `%USERPROFILE%\tools\`（pinned commit + SHA256 驗證）
3. 複製 `vscode-nvim/init.lua` + `vscode-nvim/lazy-lock.json` 到 `%LOCALAPPDATA%\nvim\`（idempotent）
4. headless 跑 `:Lazy! restore`，自動安裝 plugin 並鎖定到 lock 版本

**notepadpp/install.ps1** 會依序：

1. 用 winget 安裝 Notepad++
2. 下載並安裝 `plugins.json` 定義的 plugins（需 Admin）
3. 複製 `notepadpp/config/` 內的設定檔到 `%APPDATA%\Notepad++\`（idempotent）

**zed/install.ps1** 會依序：

1. 用 winget 安裝 Zed
2. 複製 `zed/settings.json` 到 `%APPDATA%\Zed\`（idempotent）
3. 安裝完成後提示手動填入 `github_personal_access_token`（MCP GitHub 整合用）

VSCode Profile 設定（settings、keybindings、extensions）由 **Settings Sync** 自動還原，登入帳號即可。

## im-select.exe

用途：`vscode-nvim/init.lua` 透過 `InsertLeave`/`InsertEnter` autocmd 在 Normal/Insert 模式自動切換中英文輸入法。

`vscode-nvim/install.ps1` 會自動下載並驗證 SHA256（pinned 到固定 commit）。

手動下載（如需）：

- URL: <https://raw.githubusercontent.com/daipeihust/im-select/11ed9277fb3118b63b36cfca57c39fa4cc882512/win/out/x64/im-select.exe>
- Expected SHA256: `E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6`
- 驗證（True = 正確）：

  ```powershell
  (Get-FileHash im-select.exe -Algorithm SHA256).Hash -eq `
      "E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6"
  ```

## 日常維護

### vscode-nvim

修改 `vscode-nvim/init.lua` 後：

```powershell
cd $env:USERPROFILE\dotfiles
git add vscode-nvim/init.lua
git commit -m "update: <what changed>"
git push
```

新增/升級 plugin 的完整流程（缺一步 lock 檔不會變）：

```powershell
# 1. 在 nvim 內升級或裝新 plugin
#    - 升級全部:        :Lazy update
#    - 加新 plugin spec: 編輯 init.lua 後 :Lazy install
#    - 還原到 lock 版本: :Lazy restore

# 2. 把 lazy 寫好的 lock 檔回拷到 repo
Copy-Item "$env:LOCALAPPDATA\nvim\lazy-lock.json" .\vscode-nvim\lazy-lock.json

# 3. commit
git add vscode-nvim/lazy-lock.json
git commit -m "chore: bump plugin lock"
```

### Zed

修改設定後，把最新設定回拷到 repo：

```powershell
cd $env:USERPROFILE\dotfiles
Copy-Item "$env:APPDATA\Zed\settings.json" .\zed\settings.json
git add zed/settings.json
git commit -m "update: zed settings"
git push
```

### Notepad++

更新 plugin 版本：編輯 `notepadpp/plugins.json` 內的 `version` 和 `url`，再 commit。

更新設定檔（config.xml 等）：

```powershell
cd $env:USERPROFILE\dotfiles
Copy-Item "$env:APPDATA\Notepad++\config.xml" .\notepadpp\config\config.xml
# 視需要複製其他 XML 檔
git add notepadpp/config/
git commit -m "update: notepadpp config"
git push
```

## License

MIT — see [LICENSE](LICENSE)

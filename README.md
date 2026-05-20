# wenrong's dotfiles

個人開發環境設定備份，跨機還原用。**僅支援 Windows 10/11**，使用 **[chezmoi](https://www.chezmoi.io/)** 管理。VSCode 設定由 **Settings Sync** 管理。

## 結構

```text
dotfiles/
├── AppData/                          # chezmoi 管理的設定檔（對應 %USERPROFILE%\AppData）
│   ├── Local/nvim/
│   │   ├── init.lua                  # Neovim 設定（vscode-neovim 擴充套件）
│   │   └── lazy-lock.json            # plugin 版本鎖
│   └── Roaming/
│       ├── Notepad++/                # config.xml / shortcuts.xml / stylers.xml / langs.xml / contextMenu.xml
│       └── Zed/
│           └── settings.json.tmpl   # Zed 設定（GitHub token 由 chezmoi template 填入）
├── run_once_install-neovim.ps1       # 新機器：安裝 Neovim + im-select（執行一次）
├── run_once_install-notepadpp.ps1    # 新機器：安裝 Notepad++ + 插件（執行一次）
├── run_onchange_install-zed.ps1      # 新機器：安裝 Zed（腳本變更時重新執行）
├── .chezmoi.toml.tmpl               # chezmoi 機器設定（GitHub token 等）
├── notepadpp/
│   ├── plugins.json                  # 插件清單（供 run_once 腳本讀取）
│   └── docs/
├── vscode-nvim/docs/                 # vim 使用文件（不由 chezmoi 部署，僅供參考）
├── zed/docs/
├── .gitattributes
├── .gitignore
├── LICENSE
└── README.md
```

> `*/docs/` 只是參考文件，不會被部署到系統。

## 在新機器上還原

> **注意**：Notepad++ 插件安裝需要**系統管理員**權限。建議以系統管理員身分執行 PowerShell。

```powershell
# 1. 安裝 chezmoi
winget install twpayne.chezmoi

# 2. 初始化並套用（一條命令完成全部）
chezmoi init --apply https://github.com/Wenrong274/dotfiles
```

執行後 chezmoi 會：

1. 詢問 **Zed GitHub Personal Access Token**（輸入後存在本機，不進 git）
2. 自動執行 `run_once_install-*.ps1`：用 winget 安裝 Neovim、Notepad++、Zed，以及插件
3. 把所有設定檔部署到正確位置（`%LOCALAPPDATA%\nvim\`、`%APPDATA%\Notepad++\`、`%APPDATA%\Zed\`）

VSCode Profile 由 **Settings Sync** 自動還原，登入帳號即可。

## 日常維護

### 同步設定到 repo

在任意機器修改設定後，用 chezmoi 把最新設定拉回 repo：

```powershell
# 把系統上的設定同步回 chezmoi source
chezmoi re-add

# 確認變更
chezmoi diff

# commit & push
cd $(chezmoi source-path)
git add .
git commit -m "update: <what changed>"
git push
```

### 在另一台機器拉取最新設定

```powershell
chezmoi update   # pull + apply，一條命令搞定
```

### Neovim plugin 更新

```powershell
# 1. 在 nvim 內升級 plugin
#    - 升級全部:  :Lazy update
#    - 還原 lock: :Lazy restore

# 2. 把 lazy-lock.json 同步回 chezmoi source
chezmoi re-add "$env:LOCALAPPDATA\nvim\lazy-lock.json"

# 3. commit
cd $(chezmoi source-path)
git add AppData/Local/nvim/lazy-lock.json
git commit -m "chore: bump plugin lock"
git push
```

### Notepad++ plugin 版本更新

編輯 `notepadpp/plugins.json` 的 `version` 和 `url`，再 commit。
`run_once_install-notepadpp.ps1` 因內容未變不會重跑；如要強制重裝，刪除 chezmoi 的 run_once 紀錄後重新 apply：

```powershell
# 強制重跑（慎用）
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

### GitHub token 更新

token 存在本機 `~/.config/chezmoi/chezmoi.toml`，直接編輯該檔案，或：

```powershell
chezmoi edit-config
```

改完後執行 `chezmoi apply` 讓 Zed settings.json 重新產生。

## im-select.exe

`run_once_install-neovim.ps1` 會自動下載並以 SHA256 驗證。手動下載：

- URL: <https://raw.githubusercontent.com/daipeihust/im-select/11ed9277fb3118b63b36cfca57c39fa4cc882512/win/out/x64/im-select.exe>
- Expected SHA256: `E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6`
- 驗證：

  ```powershell
  (Get-FileHash im-select.exe -Algorithm SHA256).Hash -eq `
      "E66F0A6E30B9F20787C7D4A1C57B8F2B518D36C1C7CBDBBB6220D51226DDD0B6"
  ```

## License

MIT — see [LICENSE](LICENSE)

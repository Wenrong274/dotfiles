# Notepad++ 設定說明

> 個人化設定備份，對應 chezmoi 管理的 `AppData/Roaming/Notepad++/` 與 `notepadpp/plugins.json`。

---

## 已安裝插件

透過 `notepadpp/plugins.json` 管理，`run_once_install-notepadpp.ps1` 會自動下載安裝（需 Admin）。

| 插件          | 版本     | 用途                                       |
| ------------- | -------- | ------------------------------------------ |
| AutoSave      | 2.0.0    | 自動儲存（可設間隔秒數或切換視窗時觸發）   |
| ComparePlugin | 2.0.2    | 兩個已開啟檔案的 diff 比較                 |
| ComparePlus   | 3.0.0    | 進階比較，支援 3-way merge                 |
| CSVLint       | 0.4.7    | CSV/TSV 格式驗證、欄位高亮、統計           |
| DSpellCheck   | 1.5.0    | 英文拼字檢查，支援自訂字典                 |
| MultiReplace  | 5.0.0.35 | 多條件批次取代（可匯入/匯出取代規則）      |
| NPPJSONViewer | 2.1.1.0  | JSON 格式化、樹狀結構檢視                  |
| NppTextFX     | 2.0.3    | 文字工具集（排序、去重、大小寫轉換、對齊） |
| XMLTools      | 3.1.1.13 | XML 格式化、schema 驗證、XPath 查詢        |

---

## 設定檔說明

設定檔由 chezmoi 管理，source 位置在 `AppData/Roaming/Notepad++/`，部署到 `%APPDATA%\Notepad++\`。

| 檔案              | 說明                                               |
| ----------------- | -------------------------------------------------- |
| `config.xml`      | 主要設定（字型、主題、自動換行、縮排、視窗位置等） |
| `shortcuts.xml`   | 快捷鍵自訂                                         |
| `stylers.xml`     | 語法高亮顏色主題                                   |
| `langs.xml`       | 語言定義（副檔名關聯、關鍵字清單等）               |
| `contextMenu.xml` | 右鍵選單項目自訂                                   |

---

## 日常維護

### 更新插件版本

編輯 `notepadpp/plugins.json`，修改對應的 `version` 和 `url`，再 commit：

```json
{
  "name": "ComparePlugin",
  "version": "2.0.3",
  "url": "https://github.com/pnedev/compare-plugin/releases/download/v2.0.3/ComparePlugin_v2.0.3_X64.zip"
}
```

> URL 從各插件的 GitHub Releases 頁面取得。

### 同步設定變更回 repo

在 Notepad++ 內調整設定後，用 chezmoi 把最新設定拉回：

```powershell
chezmoi re-add "$env:APPDATA\Notepad++\config.xml"
chezmoi re-add "$env:APPDATA\Notepad++\shortcuts.xml"
chezmoi re-add "$env:APPDATA\Notepad++\stylers.xml"
# 視需要 re-add 其他 XML 檔

cd (chezmoi source-path)
git add AppData/Roaming/Notepad++/
git commit -m "update: notepadpp config"
git push
```

### 重新安裝（新機器）

```powershell
# chezmoi init --apply 時會自動執行，不需手動跑
# 若需單獨重跑（以系統管理員身分執行）
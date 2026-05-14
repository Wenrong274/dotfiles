# vscode-neovim 平行試用指南

> 目標：在不破壞現有 VSCodeVim 設定的前提下，1 小時內試用 vscode-neovim，
> 評估是否真的解決卡頓問題。**整個過程可逆**。

---

## 前置確認（已具備）

- [x] Neovim binary：`C:\Program Files\Neovim\bin\nvim.exe` (v0.10.0)
- [x] init.lua：`C:\Users\wenrong.huang\AppData\Local\nvim\init.lua`（已寫好，1:1 翻譯）
- [x] im-select.exe：`~\tools\im-select.exe`（共用，不必重裝）
- [ ] vscode-neovim 擴充：**待裝**
- [ ] VSCode 設定：**待加幾行**

---

## 步驟 1：裝 vscode-neovim 擴充（2 min）

VSCode 內 `Ctrl+Shift+X` → 搜尋 **vscode-neovim** → 裝 `asvetliakov.vscode-neovim`。

---

## 步驟 2：暫時停用 VSCodeVim（30 秒）

`Ctrl+Shift+X` → 找到 **Vim**（`vscodevim.vim`）→ 點齒輪 → **Disable**。

> **不要 Uninstall**，這樣隨時能切回來。

---

## 步驟 3：加幾行 VSCode 設定（1 min）

打開 [settings.json](file:///c:/Users/wenrong.huang/AppData/Roaming/Code/User/settings.json)，**在檔案最後 `}` 之前**加入：

```jsonc
,
"vscode-neovim.neovimExecutablePaths.win32": "C:\\Program Files\\Neovim\\bin\\nvim.exe",
"vscode-neovim.compositeKeys": {
    "jj": { "command": "vscode-neovim.escape" },
    "jk": { "command": "vscode-neovim.escape" }
}
```

> `compositeKeys` 是 vscode-neovim 處理多鍵組合的方式（取代 VSCodeVim 的 insertModeKeyBindings）。

---

## 步驟 4：Reload Window（10 秒）

`Ctrl+Shift+P` → Reload Window。第一次啟動會多花 1-2 秒（spawn nvim）。

---

## 步驟 5：實測（30-60 min）

### 卡頓對比（最重要）

開你平常會卡的大檔（例如 [GameControlMgr.cs](file:///d:/DD_Wenrong/mobile/Unity/Assets/Public/GamePublic/Intl/Scripts/GameControl/GameControlMgr.cs)），執行：

| 動作 | VSCodeVim 感受 | vscode-neovim 感受 | 結論 |
|---|---|---|---|
| 連按 `j` 滾 50 行 | 卡頓？ | 順？ | __ |
| `i` 進 Insert → 打字 → `<Esc>` | 切換 lag？ | 順？ | __ |
| `<C-q>5jI// <Esc>` Block 編輯 | 偶爾失靈？ | 穩？ | __ |
| `qaQq` macro 錄製 | 掉指令？ | 穩？ | __ |
| `:%s/foo/bar/g` 全檔取代 | OK？ | OK？ | __ |

### 既有映射驗證

跑一次你熟悉的：

- [ ] `<Space>f` Quick Open
- [ ] `gd` 跳定義
- [ ] `gcc` 註解
- [ ] `<Space>U` Attach Unity
- [ ] `yae` yank 整檔
- [ ] `jj` 跳出 Insert
- [ ] `<` `>` 縮排保持選取
- [ ] `<Space><CR>` 清 highlight
- [ ] 切到中文打字，按 `<Esc>` → IME 自動跳回英文

> 任何一項失靈 → 不是 init.lua 寫錯就是 vscode-neovim 整合差異，回報我修。

---

## 步驟 6：決策

### ✅ 滿意（卡頓消失 + 映射都正常）
→ 通知我，做以下事情：
1. 把 init.lua 加入 dotfiles repo（已備好流程）
2. Uninstall VSCodeVim（騰出記憶體）
3. 從 settings.json 清掉所有 `vim.*` 設定（剩 vscode-neovim 用的就好）
4. 更新 cheatsheet / guide / 同步腳本

### ❌ 不滿意（沒改善 / 有 bug / 不喜歡）
→ **30 秒切回 VSCodeVim**：
1. `Ctrl+Shift+X` → 停用 vscode-neovim
2. 啟用 VSCodeVim
3. 從 settings.json 拿掉步驟 3 加的 3 行
4. Reload Window

**零損失**。原本所有設定都還在。

---

## 已知差異（不算 bug）

| 項目 | VSCodeVim | vscode-neovim |
|---|---|---|
| 啟動 VSCode | 即時看到 Vim | 等 ~1s 才有 Vim 模式 |
| Insert mode 文字輸入 | Vim 攔截每個 key | 大部分鍵直接給 VSCode（更順） |
| `<C-w>` `<C-c>` 等 | 你用 handleKeys 還給 VSCode | 預設就讓 VSCode 處理 |
| `vim.surround` 內建 | 直接可用 | 沒有預載，要 `ysiw"` 之類的需要 plugin |

> **Surround 暫時失效**是已知問題。如果你常用 `ysiw"`，先記著這項；可以後續加 nvim-surround plugin 解決。

---

## 之後若要永久切換

1. 在 dotfiles repo 加 `nvim/init.lua` 副本
2. 改寫 `install.ps1` 同步 nvim 配置到 `~\AppData\Local\nvim\`
3. 改寫 `sync-from-vscode.ps1` 反向同步 init.lua
4. 從 dotfiles 的 settings.json 移除 `vim.*` 設定
5. 更新 cheatsheet / guide

我可以一次幫你做完。

---

## 緊急退路

如果 reload 後 VSCode 行為完全壞掉（不太可能）：

1. `Ctrl+Shift+P` → "Extensions: Disable All Installed Extensions"
2. 再 Reload
3. 進入安全模式，逐一啟用直到找到問題擴充

---

_產生日期：2026-05-14_

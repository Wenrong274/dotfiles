# vscode-neovim 個人 Cheatsheet

> Leader = `Space` · Mode 提示：N=Normal, V=Visual, I=Insert
> 架構：真正的 Neovim 跑在背景，Insert mode 由 VSCode 原生處理（零卡頓）

---

## 一、Leader 系列（最常用）

### 檔案 / 導覽

| 鍵         | 功能                      |
| ---------- | ------------------------- |
| `<Space>f` | Quick Open（Ctrl+P 等效） |
| `<Space>e` | 切換 Explorer 側欄        |
| `<Space>d` | Problems 面板（錯誤清單） |
| `<Space>/` | 全域搜尋（Find in Files） |
| `<Space>g` | 當前檔案符號跳轉          |
| `<Space>G` | 整個 Workspace 符號跳轉   |

### 編輯 / 重構

| 鍵         | 功能                  |
| ---------- | --------------------- |
| `<Space>r` | Rename 重新命名       |
| `<Space>a` | Quick Fix（燈泡建議） |
| `<Space>o` | Organize Imports      |
| `<Space>c` | Format Document       |
| `<Space>n` | Insert Snippet        |

### 除錯 / 測試

| 鍵         | 功能                                          |
| ---------- | --------------------------------------------- |
| `<Space>b` | Toggle Breakpoint                             |
| `<Space>D` | Start Debug（一般 .NET）                      |
| `<Space>U` | **Attach Unity Debugger**（Unity 開發用這個） |
| `<Space>j` | Step Over                                     |
| `<Space>i` | Step Into                                     |
| `<Space>t` | Run Test at Cursor                            |

> Unity dev：`vstuc.refreshOnSave` 目前設為 `false`，需手動觸發 AssetDatabase refresh。

### 視窗 / Tab

| 鍵            | 功能                                 |
| ------------- | ------------------------------------ |
| `<Space>v`    | 垂直分割                             |
| `<Space>s`    | 水平分割                             |
| `<Space>w`    | 關閉當前編輯器                       |
| `<Space><CR>` | 清除搜尋 highlight                   |
| `<Space>S`    | Sort Lines Ascending（選取範圍排序） |

---

## 二、視窗 / Buffer 切換（無 Leader）

| 鍵                | 功能                  |
| ----------------- | --------------------- |
| `<C-h>` / `<C-l>` | 切換到左 / 右編輯群組 |
| `<C-j>` / `<C-k>` | 切換到下 / 上編輯群組 |
| `<S-h>` / `<S-l>` | 上一個 / 下一個 Tab   |

---

## 三、導覽（LSP）

| 鍵                | 功能                                        |
| ----------------- | ------------------------------------------- |
| `gd`              | Go to Definition                            |
| `gD`              | Peek Definition（浮動視窗，不離開當前檔案） |
| `gi`              | Go to Implementation                        |
| `gy`              | Go to Type Definition                       |
| `gr`              | Go to References                            |
| `K`               | Show Hover（型別資訊 / 文件）               |
| `]e` / `[e`       | 下一個 / 上一個 錯誤標記                    |
| `<C-o>` / `<C-i>` | VSCode 跳轉歷史 回 / 前進                   |

> vscode-neovim 使用 VSCode 的 jumplist，所以 `<C-o>` / `<C-i>` 與滑鼠跳定義等行為整合。

---

## 四、Insert Mode 跳脫

| 鍵      | 功能          | 機制                       |
| ------- | ------------- | -------------------------- |
| `jj`    | → Normal Mode | compositeKeys（VSCode 層） |
| `jk`    | → Normal Mode | compositeKeys（VSCode 層） |
| `<Esc>` | → Normal Mode | 原生                       |

> Insert mode 由 VSCode 原生處理，`jj`/`jk` 透過 settings.json 的 `compositeKeys` 設定，不是 Lua imap。

---

## 五、Visual Mode

| 鍵        | 功能                                    |
| --------- | --------------------------------------- |
| `v`       | 字元 visual                             |
| `V`       | 行 visual                               |
| `<C-q>`   | **Block (方塊) visual**（替代 `<C-v>`） |
| `gc`      | 註解選取行                              |
| `<` / `>` | 縮排（**保留選取**）                    |
| `p`       | 貼上並丟棄被取代內容（不污染 register） |
| `vae`     | 選整個檔案（V→gg→G）                    |

### Visual Block 典型用法

```text
<C-q> 5j I // <Esc>       選 6 行，每行行首插入 "// "
<C-q> 3j $ A ;<Esc>       選 4 行，每行行尾加 ";"
<C-q> 5j c FOO <Esc>      選 6 行同位置，全換成 "FOO"
```

Normal mode 還有：

| 鍵    | 功能         |
| ----- | ------------ |
| `gcc` | 註解當前行   |
| `yae` | 複製整個檔案 |
| `dae` | 刪除整個檔案 |

---

## 六、Surround（nvim-surround 插件）

| 鍵                 | 功能                     | 範例            |
| ------------------ | ------------------------ | --------------- |
| `ysiw"`            | 用 `"` 圍住游標所在 word | `foo` → `"foo"` |
| `ys$)`             | 用 `()` 圍住到行尾       |                 |
| `cs"'`             | 把 `"..."` 換成 `'...'`  |                 |
| `ds"`              | 刪除外圍 `"`             |                 |
| Visual 選取後 `S"` | 圍住選取區               |                 |

---

## 七、CamelCaseMotion（C# 神器）

對 `MyVariableName` / `getUserName` 這類駝峰命名拆字移動：

| 鍵              | 動作                                             |
| --------------- | ------------------------------------------------ |
| `,w`            | 跳到下一個駝峰段開頭（My**V**ariable**N**ame）   |
| `,b`            | 跳到上一個駝峰段開頭                             |
| `,e`            | 跳到下一個駝峰段結尾                             |
| `ci,w`          | 改當前駝峰段（例如游標在 `Variable` → 整段刪改） |
| `di,w` / `yi,w` | 刪 / 複製當前駝峰段                              |

> 原生 `w` `b` `e` 不受影響，仍是整個 word。

---

## 八、Flash.nvim（跳躍式移動）

觸發：`<Space><Space>`（即 Leader Leader）

| 步驟                            | 動作                         |
| ------------------------------- | ---------------------------- |
| 1. 按 `<Space><Space>`          | 畫面進入 Flash 模式          |
| 2. 打你要跳過去的字（1~2 字元） | 畫面上所有匹配處出現標記字母 |
| 3. 按標記字母                   | 直接跳到該位置               |

**何時用**：移動超過 5 行，或想跳到畫面上任意位置時。比 Easymotion 更直覺——直接打目標文字即可。

---

## 九、Vim 原生常用備忘

### 文字物件（Text Objects）

| 鍵          | 範圍                                                   |
| ----------- | ------------------------------------------------------ |
| `iw` / `aw` | inner / a word                                         |
| `i"` / `a"` | inner / a `"..."`                                      |
| `i(` / `a(` | inner / a `(...)`                                      |
| `i{` / `a{` | inner / a `{...}`                                      |
| `ip` / `ap` | inner / a paragraph                                    |
| `it` / `at` | inner / a tag                                          |
| `i<` / `a<` | inner / a `<...>`（C# generics 適用，已加 matchpairs） |

組合：`ci"` 改裡面、`da{` 刪整塊、`yi(` yank 括號內

### 暫存器 / 巨集

- `"ay` 複製到 register `a`，`"ap` 貼上
- `"+y` 複製到系統剪貼簿
- `qa` 開始錄製到 `a`，`q` 結束，`@a` 執行

### Ex 指令

- `:%s/foo/bar/g` 全檔取代
- `:'<,'>s/foo/bar/g` Visual 選取範圍內取代
- `:noh` 清除 highlight（已綁 `<Space><CR>`）

---

## 十、vscode-neovim 架構備忘

| 項目                 | 說明                                                                    |
| -------------------- | ----------------------------------------------------------------------- |
| Insert mode          | 由 VSCode 原生處理（不經 Neovim），所以打字零卡頓                       |
| Normal / Visual mode | 由背景 Neovim 處理，完整 Vim 語法                                       |
| `jj` / `jk` escape   | 透過 `compositeKeys` 設定（settings.json），不是 Lua imap               |
| 啟動時間             | 比 VSCodeVim 多 ~1 秒（spawn Neovim process）                           |
| Ctrl 系列            | 大部分 `Ctrl+` 鍵在 Insert mode 自然歸 VSCode 處理，不需額外設定        |
| IME 切換             | 透過 Neovim autocmd + im-select.exe 自動處理                            |
| 行號顯示             | `editor.lineNumbers: "relative"` — 相對行號，直接看 `5j`/`12k` 要跳幾行 |
| 滑鼠拖選             | `mouseSelectionStartVisualMode: true` — 滑鼠拖選自動進 Visual mode      |
| 設定位置             | Neovim：`%LOCALAPPDATA%\nvim\init.lua` / VSCode：`settings.json`        |

---

_最後更新：2026-05-18_
_設定檔位置：`%LOCALAPPDATA%\nvim\init.lua` + `%APPDATA%\Code\User\settings.json`_

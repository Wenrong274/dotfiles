# VSCode Vim 個人 Cheatsheet

> Leader = `Space`  ·  Mode 提示：N=Normal, V=Visual, I=Insert

---

## 一、Leader 系列（最常用）

### 檔案 / 導覽

| 鍵 | 功能 |
|---|---|
| `<Space>f` | Quick Open（Ctrl+P 等效） |
| `<Space>e` | 切換 Explorer 側欄 |
| `<Space>/` | 全域搜尋（Find in Files） |
| `<Space>g` | 當前檔案符號跳轉 |
| `<Space>G` | 整個 Workspace 符號跳轉 |

### 編輯 / 重構

| 鍵 | 功能 |
|---|---|
| `<Space>r` | Rename 重新命名 |
| `<Space>a` | Quick Fix（燈泡建議） |
| `<Space>o` | Organize Imports |
| `<Space>c` | Format Document |
| `<Space>n` | Insert Snippet |

### 除錯 / 測試

| 鍵 | 功能 |
|---|---|
| `<Space>b` | Toggle Breakpoint |
| `<Space>D` | Start Debug |
| `<Space>j` | Step Over |
| `<Space>i` | Step Into |
| `<Space>t` | Run Test at Cursor |

### 視窗 / Tab

| 鍵 | 功能 |
|---|---|
| `<Space>v` | 垂直分割 |
| `<Space>s` | 水平分割 |
| `<Space>w` | 關閉當前編輯器 |
| `<Space><CR>` | 清除搜尋 highlight |

---

## 二、視窗 / Buffer 切換（無 Leader）

| 鍵 | 功能 |
|---|---|
| `<C-h>` / `<C-l>` | 切換到左 / 右編輯群組 |
| `<C-j>` / `<C-k>` | 切換到下 / 上編輯群組 |
| `<S-h>` / `<S-l>` | 上一個 / 下一個 Tab |

---

## 三、導覽（LSP）

| 鍵 | 功能 |
|---|---|
| `gd` | Go to Definition |
| `gi` | Go to Implementation |
| `gy` | Go to Type Definition |
| `gr` | Go to References |
| `]e` / `[e` | 下一個 / 上一個 錯誤標記 |
| `<C-o>` / `<C-i>` | Vim jumplist 回 / 前進（原生） |

---

## 四、Insert Mode 跳脫

| 鍵 | 功能 |
|---|---|
| `jj` | → Normal Mode |
| `jk` | → Normal Mode |
| `<Esc>` | → Normal Mode |

---

## 五、Visual Mode

| 鍵 | 功能 |
|---|---|
| `gc` | 註解選取行 |
| `<` / `>` | 縮排（**保留選取**） |
| `vae` | 選整個檔案（V→gg→G） |

Normal mode 還有：

| 鍵 | 功能 |
|---|---|
| `gcc` | 註解當前行 |
| `yae` | 複製整個檔案 |
| `dae` | 刪除整個檔案 |

---

## 六、Surround（`vim.surround` 已開）

| 鍵 | 功能 | 範例 |
|---|---|---|
| `ysiw"` | 用 `"` 圍住游標所在 word | `foo` → `"foo"` |
| `ys$)` | 用 `()` 圍住到行尾 |  |
| `cs"'` | 把 `"..."` 換成 `'...'` |  |
| `ds"` | 刪除外圍 `"` |  |
| Visual 選取後 `S"` | 圍住選取區 |  |

---

## 七、CamelCaseMotion（已開啟，C# 神器）

對 `MyVariableName` / `getUserName` 這類駝峰命名拆字移動：

| 鍵 | 動作 |
|---|---|
| `,w` | 跳到下一個駝峰段開頭（My**V**ariable**N**ame） |
| `,b` | 跳到上一個駝峰段開頭 |
| `,e` | 跳到下一個駝峰段結尾 |
| `ci,w` | 改當前駝峰段（例如游標在 `Variable` → 整段刪改） |
| `di,w` / `yi,w` | 刪 / 複製當前駝峰段 |

> 原生 `w` `b` `e` 不受影響，仍是整個 word。

---

## 八、Easymotion（已開啟）

預設觸發前綴：`<leader><leader>`（即 `Space Space`）

| 鍵 | 功能 |
|---|---|
| `<Space><Space>w` | 跳到下一個 word 開頭 |
| `<Space><Space>b` | 跳到上一個 word 開頭 |
| `<Space><Space>f{char}` | 跳到指定字元 |
| `<Space><Space>j` / `k` | 跳到下 / 上一行 |
| `<Space><Space>/` | search 模式跳轉 |

---

## 八、還給 VSCode 的快捷鍵（vim.handleKeys）

不被 Vim 攔截，行為與一般 VSCode 一致：

`Ctrl+A` 全選 ·  `Ctrl+C` 複製 ·  `Ctrl+V` 貼上 ·  `Ctrl+Z/Y` Undo/Redo ·  `Ctrl+F` 檔內搜尋 ·  `Ctrl+S` 存檔 ·  `Ctrl+W` 關閉編輯器 ·  `Ctrl+N` 新檔 ·  `Ctrl+P` Command Palette

---

## 九、Vim 原生常用備忘

### 文字物件（Text Objects）

| 鍵 | 範圍 |
|---|---|
| `iw` / `aw` | inner / a word |
| `i"` / `a"` | inner / a `"..."` |
| `i(` / `a(` | inner / a `(...)` |
| `i{` / `a{` | inner / a `{...}` |
| `ip` / `ap` | inner / a paragraph |
| `it` / `at` | inner / a tag |

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

## 十、待習慣的小提醒

- Leader = Space，所以單按 `f`（find char）會延遲 700ms 才觸發 → 已設 `vim.timeout: 700`
- `<C-o>` / `<C-i>` 是 Vim jumplist，**不是** VSCode 編輯歷史；要看編輯歷史用 Command Palette → "Go Back / Forward"
- `<C-w>` 已還給 VSCode（關 Tab），失去 Vim window 指令；視窗切換改用 `<C-h/j/k/l>` 與 `<Space>v/s`

---

_最後更新：2026-05-13_
_設定檔位置：`%APPDATA%\Code\User\settings.json`_

# Vim 使用文件（個人化版）

> 本文件針對 **VSCode + vscode-neovim 擴充** 的使用情境撰寫，並對應你目前在 `init.lua` + `settings.json` 中的個人設定（Leader = `Space`）。
> 速查請見 [vim-cheatsheet.md](./vim-cheatsheet.md)，本文重在**理解 Vim 思維**與**為什麼這樣設**。

---

## 目錄

1. [Vim 的核心思維](#1-vim-的核心思維)
2. [四種模式](#2-四種模式)
3. [移動：把游標當成一等公民](#3-移動把游標當成一等公民)
4. [動詞 + 文字物件 = Vim 的力量](#4-動詞--文字物件--vim-的力量)
5. [搜尋與取代](#5-搜尋與取代)
6. [複製貼上與 Registers](#6-複製貼上與-registers)
7. [Marks、Jumps、Macros](#7-marksjumpsmacros)
8. [Surround：包覆操作](#8-surround包覆操作)
9. [Flash.nvim：跳躍式移動](#9-flashnvim跳躍式移動)
10. [VSCode 整合的最佳實踐](#10-vscode-整合的最佳實踐)
11. [學習路徑建議](#11-學習路徑建議)
12. [常見踩雷與對策](#12-常見踩雷與對策)

---

## 1. Vim 的核心思維

Vim 不是「能用鍵盤的文字編輯器」——它是一套**語法**。

```text
動詞 (operator)  +  名詞 (motion / text object)
```

例如：

- `d` (delete) + `w` (word) → `dw` 刪一個 word
- `c` (change) + `i"` (inner quote) → `ci"` 改 `"..."` 內容
- `y` (yank) + `ap` (a paragraph) → `yap` 複製一整段含空行

**只要會三、四個動詞和十幾個 motion，組合出來就是上百個指令。** 這就是為什麼 Vim 玩家不太重複勞動——他們在**表達編輯意圖**，而不是在**敲鍵盤**。

> 一句話總結：**少按鍵 ≠ Vim 的目的。表達準確的編輯意圖 = Vim 的目的。**

---

## 2. 四種模式

| 模式             | 進入方式                            | 用途                                     |
| ---------------- | ----------------------------------- | ---------------------------------------- |
| **Normal**       | 預設 / `<Esc>` / `jj` / `jk`        | 移動、執行指令。**99% 時間應該停在這裡** |
| **Insert**       | `i` `a` `o` `I` `A` `O`             | 真的在打字（由 VSCode 原生處理）         |
| **Visual**       | `v`（字元）`V`（行）`<C-q>`（區塊） | 選取後對選取區操作                       |
| **Command-line** | `:` `/` `?`                         | 執行 ex 指令 / 搜尋                      |

### 進入 Insert 的六種姿勢

| 鍵  | 在哪裡開始打字           |
| --- | ------------------------ |
| `i` | 游標**前**               |
| `a` | 游標**後**（append）     |
| `I` | 行首（第一個非空白字元） |
| `A` | 行尾                     |
| `o` | 新增**下一行**           |
| `O` | 新增**上一行**           |

**初學者最常見的錯誤**：一直停在 Insert 模式，需要移動時用方向鍵。**請強迫自己每打完一句話就 `<Esc>`（或 `jj`）回到 Normal。**

### vscode-neovim 的 Insert mode 特性

在 vscode-neovim 中，Insert mode 由 VSCode 原生處理（不經過 Neovim），所以：

- 打字完全不卡頓
- `Ctrl+A/C/V/Z/Y/F/S/W/N/P` 等 VSCode 快捷鍵自然可用，不需額外設定
- `jj`/`jk` 透過 settings.json 的 `compositeKeys` 處理（不是 Lua imap）

---

## 3. 移動：把游標當成一等公民

### 基礎移動

```text
        k (上)
h (左)  ←  →  l (右)
        j (下)
```

### 以「字」為單位

| 鍵  | 動作                           |
| --- | ------------------------------ |
| `w` | 下一個 word 開頭（標點算分界） |
| `W` | 下一個 WORD 開頭（只看空白）   |
| `b` | 上一個 word 開頭               |
| `e` | 下一個 word 結尾               |

### 以「行」為單位

| 鍵             | 動作                 |
| -------------- | -------------------- |
| `0`            | 行首                 |
| `^`            | 行首（第一個非空白） |
| `$`            | 行尾                 |
| `gg`           | 檔首                 |
| `G`            | 檔尾                 |
| `42G` 或 `:42` | 跳到第 42 行         |

### 以「畫面」為單位

| 鍵                 | 動作                       |
| ------------------ | -------------------------- |
| `<C-d>` / `<C-u>`  | 下 / 上半頁                |
| `H` / `M` / `L`    | 畫面上 / 中 / 下           |
| `zz` / `zt` / `zb` | 把當前行置中 / 置頂 / 置底 |

### 行內精準跳躍

| 鍵        | 動作                           |
| --------- | ------------------------------ |
| `f{c}`    | 跳到本行下一個字元 `c`         |
| `F{c}`    | 反方向                         |
| `t{c}`    | 跳到 `c` **前一格**            |
| `;` / `,` | 重複上一個 `f`/`t` 正向 / 反向 |

> 範例：要改 `name = "foo"` 裡的 `foo`，從行首按 `f"l` 進入引號內，或更快 `ci"`。
>
> **注意**：`,` 同時是 CamelCaseMotion 的前綴。如果按 `,` 後等了 700ms 才觸發 `f`/`t` 重複，這是正常的 — Neovim 在等你有沒有要按 `,w`/`,b`/`,e`。

---

## 4. 動詞 + 文字物件 = Vim 的力量

### 常用動詞（Operators）

| 動詞      | 動作                      |
| --------- | ------------------------- |
| `d`       | delete（剪下）            |
| `c`       | change（刪除並進 Insert） |
| `y`       | yank（複製）              |
| `>` `<`   | 縮排                      |
| `=`       | 自動縮排                  |
| `gU` `gu` | 轉大 / 小寫               |

### 文字物件（Text Objects）

語法：`i` (inner) / `a` (around) + 物件

| 物件            | 範圍                                                       |
| --------------- | ---------------------------------------------------------- |
| `w`             | word                                                       |
| `s`             | sentence                                                   |
| `p`             | paragraph                                                  |
| `"` `'` `` ` `` | 引號內                                                     |
| `(` `)` `b`     | 小括號內                                                   |
| `{` `}` `B`     | 大括號內                                                   |
| `[` `]`         | 中括號內                                                   |
| `<` `>`         | 角括號內（C# generics 適用，已加 matchpairs）              |
| `t`             | XML/HTML tag                                               |
| `a`             | **函式引數**（mini.ai 提供，原生 vim 沒有）                |
| `q`             | 任意引號（mini.ai：自動找最近的 `"`/`'`/`` ` ``）          |
| `b` *           | 任意 brackets（mini.ai：自動找最近的 `()`/`[]`/`{}`）      |

> *`b` 同時是原生 vim 的小括號和 mini.ai 的「任意 brackets」。實務上 mini.ai 的 `ib`/`ab` 會找最近的括號，更通用。
>
> **函式引數的威力**：`foo(a, b, c)` 游標在 `b` 上 → `dia` 變 `foo(a, , c)`（只刪本體）→ `daa` 變 `foo(a, c)`（含逗號）。重構函式呼叫超快。

### 組合範例（**這就是 Vim**）

```text
情境                        指令         結果
─────────────────────────────────────────────────────────────
改函式參數內容              ci(          清空 () 內並開始打字
複製整段註解                yap          複製段落＋後空行
刪除字串內容                di"          清空 "" 內保留引號
把整個 method body 上排     =i{          自動縮排 {} 內所有行
變數名改大寫                gUiw         把 word 整個轉大寫
刪到行尾                    d$          剪掉游標到行尾
複製到某字元                yt;          複製到下一個 ; 之前
```

### 重複次數

所有指令前可加數字：

- `5j` 下移 5 行
- `3dw` 刪 3 個 word
- `2ci"` 改第二層引號內（罕用）

---

## 5. 搜尋與取代

### 搜尋

| 鍵            | 動作                                               |
| ------------- | -------------------------------------------------- |
| `/foo`        | 向下搜尋 foo                                       |
| `?foo`        | 向上搜尋                                           |
| `n` / `N`     | 下 / 上一個（**自動置中** — 已映射為 `nzz`/`Nzz`） |
| `*`           | 搜尋游標下的 word（向下）                          |
| `#`           | 搜尋游標下的 word（向上）                          |
| `<Space><CR>` | 清除 highlight（你的個人綁定）                     |

> 個人設定：`n`/`N` 跳完會把游標所在行置中（`zz`），避免結果落到畫面邊緣難讀。同樣套用於 `<C-d>`/`<C-u>` 半頁滾動。

### 取代（Ex 指令）

```vim
:s/foo/bar/         " 本行第一個 foo → bar
:s/foo/bar/g        " 本行所有 foo
:%s/foo/bar/g       " 全檔所有 foo
:%s/foo/bar/gc      " 全檔，每次詢問 (y/n/a/q)
:5,20s/foo/bar/g    " 第 5–20 行
:'<,'>s/foo/bar/g   " Visual 選取範圍
```

旗標：

- `g` global（本行所有）
- `c` confirm
- `i` ignorecase

### 你的設定如何影響搜尋

在 init.lua 中設定了：

```lua
vim.opt.ignorecase = true    -- 忽略大小寫
vim.opt.smartcase  = true    -- 但有大寫時恢復敏感
-- hlsearch / incsearch 是 Neovim 預設 ON，未顯式設定
```

所以 `/foo` 會匹配 foo/Foo/FOO，但 `/Foo` 只匹配 Foo。搜尋會邊打邊高亮（incsearch + hlsearch 預設行為），按 `<Space><CR>` 清除 highlight。

---

## 6. 複製貼上與 Registers

### 預設行為

- `yy` 複製一整行（含換行）
- `p` 貼到游標**後**
- `P` 貼到游標**前**

> 已設 `vim.opt.clipboard = 'unnamedplus'`，所以 yank/delete 自動同步系統剪貼簿。

### Registers（暫存器）

語法：`"x{動作}`，x 是 register 名稱

| Register | 用途                                           |
| -------- | ---------------------------------------------- |
| `"`      | 預設 register（剛 yank/delete 的內容）         |
| `0`      | 最近一次 yank（不含 delete）                   |
| `1`–`9`  | 最近 9 次 delete                               |
| `+`      | **系統剪貼簿**（與預設同步，因為 unnamedplus） |
| `a`–`z`  | 你自己用                                       |
| `_`      | 黑洞（丟棄）                                   |

### 實用範例

```text
yy              複製整行（自動進系統剪貼簿）
p               貼上
"ayw            複製 word 到 register a
"ap             從 register a 貼上
"_dd            刪除一行但不動剪貼簿（黑洞）
```

> **常見痛點**：`dd` 會把刪掉的內容塞進預設 register，覆蓋剛 yank 的內容。解法：刪除前用 `"_dd`，或養成 `"0p` 貼 yank 內容的習慣。

---

## 7. Marks、Jumps、Macros

### Marks（書籤）

- `ma` 把當前位置存到 mark a
- `` `a `` 跳回 mark a（精確位置）
- `'a` 跳回 mark a 那一行
- 大寫 `A`–`Z`：跨檔案的全域 mark

### Jumplist（跳轉歷史）

- `<C-o>` 跳回上一個位置
- `<C-i>` 往前
- `:jumps` 看清單

> vscode-neovim 使用 VSCode 的 jumplist（不是 Neovim 內建的），所以滑鼠點擊跳定義等操作也會記錄在跳轉歷史中。

### Macros（巨集）

錄製重複動作：

```text
qa              開始錄製到 register a
{做一連串動作}
q               停止錄製
@a              播放一次
10@a            播放 10 次
@@              重播上一個 macro
```

> 範例：要把 20 行 `name = "foo";` 改成 `Name = "foo",`：
> `qa` → `^gU l f; r,` → `j` → `q` → `19@a`

---

## 8. Surround：包覆操作

使用 **nvim-surround** 插件（透過 lazy.nvim 安裝）。語法與 vim-surround 相同：

### 新增包覆（`ys` = you surround）

```text
ysiw"           "foo"      把 word 用 "" 包起來
ys$)            (rest)     從游標到行尾用 () 包
yss"            "整行"     整行用 "" 包
```

### 修改包覆（`cs` = change surround）

```text
cs"'            "foo" → 'foo'
cs([            (foo) → [ foo ]    用 ( 會留空格，[ 不留
cs[(            [ foo ] → (foo)
```

### 刪除包覆（`ds`）

```text
ds"             "foo" → foo
ds(             (foo) → foo
dst             <b>foo</b> → foo  （t 是 tag）
```

### Visual 模式包覆

選取一段後按 `S"` 即可包覆。

---

## 9. Flash.nvim：跳躍式移動

觸發：`<Space><Space>`（即 Leader Leader）

### 使用方式

1. 按 `<Space><Space>` — 畫面進入 Flash 模式
2. 開始打你想跳過去的文字（1~2 個字元即可）
3. 畫面上所有匹配位置會出現標記字母
4. 按對應的標記字母 — 直接跳到該位置

### 與 Easymotion 的差異

|          | Easymotion (舊)                        | Flash.nvim (現在)             |
| -------- | -------------------------------------- | ----------------------------- |
| 觸發方式 | `<Space><Space>w` / `f` / `j` 等子指令 | `<Space><Space>` 直接開始打字 |
| 搜尋方式 | 固定範圍（word / 行 / 字元）           | 打任意文字即時匹配            |
| 直覺性   | 需要記子指令                           | 直接打目標文字，更自然        |

**何時用**：移動超過 5 行、或想跳到畫面上任意位置時。

---

## 10. VSCode 整合的最佳實踐

### 原則

**讓 Neovim 處理「文字編輯」（Normal/Visual），讓 VSCode 處理「打字和 IDE 功能」（Insert）。**

| 該由 Neovim 處理             | 該由 VSCode 處理      |
| ---------------------------- | --------------------- |
| 移動、選取、刪除、複製       | Insert mode 打字輸入  |
| 替換、巨集、文字物件         | LSP（跳定義、重命名） |
| 行內精準編輯                 | Debug、Run、測試      |
| Surround / Flash / CamelCase | 檔案總管、Git、終端   |

### 你已綁好的橋樑（Leader 系列）

透過 init.lua 中的 `vim.fn.VSCodeNotify()` 呼叫 VSCode 指令：

- `<Space>r` rename ← LSP
- `<Space>a` quick fix ← LSP
- `<Space>g` / `<Space>G` 符號跳轉 ← LSP
- `<Space>/` 全域搜尋 ← VSCode
- `gd` / `gi` / `gy` / `gr` LSP 導覽
- `<Space>b` / `<Space>D` / `<Space>U` Debug

### Insert mode 的 Ctrl 快捷鍵

vscode-neovim 不攔截 Insert mode 按鍵（由 VSCode 原生處理），所以 `Ctrl+A/C/V/Z/Y/F/S/W/N/P` 等都自然可用，不需像 VSCodeVim 那樣用 `handleKeys` 設定。

---

## 11. 學習路徑建議

詳細的 4 週執行計畫（每週目標、每日規則、練習題、週末測試）見 [vim-onboarding.md](./vim-onboarding.md)。

以下是精簡版里程碑：

| 週次 | 目標 | 關鍵指令 |
| ---- | ---- | -------- |
| 第 1 週 | 不再用方向鍵 | `hjkl` `w` `b` `0` `$` `gg` `G` |
| 第 2 週 | 動詞 + 物件取代選取 | `ciw` `di"` `ya{` `f{c}` |
| 第 3 週 | Leader 快捷鍵進肌肉記憶 | `<Space>f/r/a` `gd` `<C-o>` |
| 第 4 週+ | 進階工具按需取用 | Flash / Surround / CamelCase / Macros |

### 不要太早碰

- `<C-q>` 區塊選取（強大但難）
- 複雜的 `:g/pattern/d` 操作
- 自訂 Neovim 插件（先用好現有的三個就夠了）

---

## 12. 常見踩雷與對策

### 雷 1：一直停在 Insert 模式

**症狀**：方向鍵移動、Esc 鍵都按到小指痛。
**解法**：強迫自己「打完一個小段就 `jj` 出來」。一週後肌肉記憶就形成。

### 雷 2：剛 yank 的東西被 `dd` 覆蓋

**症狀**：複製一段、刪一行、貼上，發現貼出來是被刪的那行。
**解法**：用 `"0p` 貼最近一次 yank；或刪用 `"_dd`。

### 雷 3：Leader 延遲讓 `,` 變慢

**症狀**：按 `,` 想重複 `f`/`t`，要等一會兒才反應（因為 CamelCaseMotion 用 `,` 前綴）。
**解法**：已設 `vim.opt.timeoutlen = 700`。養成習慣：要重複 `f`/`t` 用 `;`（不受影響），`,` 留給 CamelCaseMotion。

### 雷 4：`jj` 在 Normal mode 移動兩行

**症狀**：按 `jj` 沒有 escape。
**解法**：`jj` 只在 **Insert mode** 生效。在 Normal mode 下 `j` 就是「向下一行」，所以 `jj` 會向下兩行——這是正確行為。

### 雷 5：中文輸入法切換忘了切回英文（已自動處理）

**症狀**：在 Normal mode 按 `j` 跑出「ㄨ」。
**已自動化**：透過 Neovim autocmd + `im-select.exe` 達成：

- 離開 Insert mode → 自動切回英文 (`1033`)
- 進入 Insert mode → 自動還原上次的 IME（中文/英文）

**Binary 位置**：`%USERPROFILE%\tools\im-select.exe`
**驗證**：開終端機跑 `~\tools\im-select.exe` 會印出當前 IME 代碼（1028=繁中, 1033=英文）

### 雷 6：VSCode 啟動後 Vim 慢一拍才能用

**症狀**：開 VSCode 約 1 秒內 Vim 模式還沒啟動。
**原因**：vscode-neovim 需要 spawn Neovim 背景 process，開機時需 ~1 秒。不影響使用。

---

## 附錄：你的設定一覽

| 項目                   | 設定                                       |
| ---------------------- | ------------------------------------------ |
| Leader                 | `Space`                                    |
| 擴充                   | vscode-neovim (asvetliakov)                |
| Neovim 版本            | 依 winget 安裝（`winget install Neovim.Neovim`） |
| 插件管理               | lazy.nvim                                  |
| 插件                   | nvim-surround, flash.nvim, CamelCaseMotion, mini.ai |
| hlsearch / incsearch   | ✅                                         |
| ignorecase + smartcase | ✅                                         |
| clipboard              | unnamedplus（同步系統剪貼簿）              |
| timeoutlen             | 700ms                                      |
| scrolloff              | 5                                          |
| matchpairs             | 含 `<:>`（C# generics）                    |
| yank 高亮              | 200ms（`vim.hl.on_yank` autocmd）          |
| IME 切換               | im-select.exe + Neovim autocmd             |
| `jj` / `jk` escape     | compositeKeys（settings.json）             |

設定檔：

- Neovim：`%LOCALAPPDATA%\nvim\init.lua`
- VSCode：`%APPDATA%\Code\User\settings.json`
- 速查表：[vim-cheatsheet.md](./vim-cheatsheet.md)

---

最後更新：2026-05-19

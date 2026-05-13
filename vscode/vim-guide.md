# Vim 使用文件（個人化版）

> 本文件針對 **VSCode + VSCodeVim 擴充** 的使用情境撰寫，並對應你目前在 `settings.json` 中的個人設定（Leader = `Space`）。
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
9. [Easymotion：跳躍式移動](#9-easymotion跳躍式移動)
10. [VSCode 整合的最佳實踐](#10-vscode-整合的最佳實踐)
11. [學習路徑建議](#11-學習路徑建議)
12. [常見踩雷與對策](#12-常見踩雷與對策)

---

## 1. Vim 的核心思維

Vim 不是「能用鍵盤的文字編輯器」——它是一套**語法**。

```
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

| 模式 | 進入方式 | 用途 |
|---|---|---|
| **Normal** | 預設 / `<Esc>` / `jj` / `jk` | 移動、執行指令。**99% 時間應該停在這裡** |
| **Insert** | `i` `a` `o` `I` `A` `O` | 真的在打字 |
| **Visual** | `v`（字元）`V`（行）`<C-v>`（區塊） | 選取後對選取區操作 |
| **Command-line** | `:` `/` `?` | 執行 ex 指令 / 搜尋 |

### 進入 Insert 的六種姿勢
| 鍵 | 在哪裡開始打字 |
|---|---|
| `i` | 游標**前** |
| `a` | 游標**後**（append） |
| `I` | 行首（第一個非空白字元） |
| `A` | 行尾 |
| `o` | 新增**下一行** |
| `O` | 新增**上一行** |

**初學者最常見的錯誤**：一直停在 Insert 模式，需要移動時用方向鍵。**請強迫自己每打完一句話就 `<Esc>`（或 `jj`）回到 Normal。**

---

## 3. 移動：把游標當成一等公民

### 基礎移動
```
        k (上)
h (左)  ←  →  l (右)
        j (下)
```

### 以「字」為單位
| 鍵 | 動作 |
|---|---|
| `w` | 下一個 word 開頭（標點算分界） |
| `W` | 下一個 WORD 開頭（只看空白） |
| `b` | 上一個 word 開頭 |
| `e` | 下一個 word 結尾 |

### 以「行」為單位
| 鍵 | 動作 |
|---|---|
| `0` | 行首 |
| `^` | 行首（第一個非空白） |
| `$` | 行尾 |
| `gg` | 檔首 |
| `G` | 檔尾 |
| `42G` 或 `:42` | 跳到第 42 行 |

### 以「畫面」為單位
| 鍵 | 動作 |
|---|---|
| `<C-d>` / `<C-u>` | 下 / 上半頁 |
| `H` / `M` / `L` | 畫面上 / 中 / 下 |
| `zz` / `zt` / `zb` | 把當前行置中 / 置頂 / 置底 |

### 行內精準跳躍
| 鍵 | 動作 |
|---|---|
| `f{c}` | 跳到本行下一個字元 `c` |
| `F{c}` | 反方向 |
| `t{c}` | 跳到 `c` **前一格** |
| `;` / `,` | 重複上一個 `f`/`t` 正向 / 反向 |

> 範例：要改 `name = "foo"` 裡的 `foo`，從行首按 `f"l` 進入引號內，或更快 `ci"`。

---

## 4. 動詞 + 文字物件 = Vim 的力量

### 常用動詞（Operators）
| 動詞 | 動作 |
|---|---|
| `d` | delete（剪下） |
| `c` | change（刪除並進 Insert） |
| `y` | yank（複製） |
| `>` `<` | 縮排 |
| `=` | 自動縮排 |
| `gU` `gu` | 轉大 / 小寫 |

### 文字物件（Text Objects）
語法：`i` (inner) / `a` (around) + 物件

| 物件 | 範圍 |
|---|---|
| `w` | word |
| `s` | sentence |
| `p` | paragraph |
| `"` `'` `` ` `` | 引號內 |
| `(` `)` `b` | 小括號內 |
| `{` `}` `B` | 大括號內 |
| `[` `]` | 中括號內 |
| `<` `>` | 角括號內 |
| `t` | XML/HTML tag |

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
| 鍵 | 動作 |
|---|---|
| `/foo` | 向下搜尋 foo |
| `?foo` | 向上搜尋 |
| `n` / `N` | 下 / 上一個 |
| `*` | 搜尋游標下的 word（向下） |
| `#` | 搜尋游標下的 word（向上） |
| `<Space><CR>` | 清除 highlight（你的個人綁定） |

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
你開了：
```jsonc
"vim.hlsearch": true,    // 搜尋結果高亮
"vim.incsearch": true,   // 邊打邊搜
"vim.ignorecase": true,  // 忽略大小寫
"vim.smartcase": true    // 但有大寫時恢復敏感
```
所以 `/foo` 會匹配 foo/Foo/FOO，但 `/Foo` 只匹配 Foo。

---

## 6. 複製貼上與 Registers

### 預設行為
- `yy` 複製一整行（含換行）
- `p` 貼到游標**後**
- `P` 貼到游標**前**

### Registers（暫存器）
語法：`"x{動作}`，x 是 register 名稱

| Register | 用途 |
|---|---|
| `"` | 預設 register（剛 yank/delete 的內容） |
| `0` | 最近一次 yank（不含 delete） |
| `1`–`9` | 最近 9 次 delete |
| `+` | **系統剪貼簿**（重要！） |
| `a`–`z` | 你自己用 |
| `_` | 黑洞（丟棄） |

### 實用範例
```text
"+yy            複製整行到系統剪貼簿
"+p             從系統剪貼簿貼上
"ayw            複製 word 到 register a
"ap             從 register a 貼上
"_dd            刪除一行但不進剪貼簿（黑洞）
```

> **常見痛點**：vim 預設 `dd` 會把刪掉的內容塞進預設 register，導致剛 yank 的東西被覆寫。解法：刪除前用 `"_dd`，或養成 `"0p` 貼 yank 內容的習慣。

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

> 你已經把 `<C-o>` / `<C-i>` 還給 Vim 原生（從 VSCode navigateBack 改回 Vim jumplist）。要看 VSCode 編輯歷史請用 Command Palette。

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

你已啟用 `vim.surround: true`。語法：

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

## 9. Easymotion：跳躍式移動

預設前綴：`<leader><leader>`（即 `Space Space`）

| 鍵 | 動作 |
|---|---|
| `<Space><Space>w` | 在畫面所有 word 開頭打標記，按標記跳轉 |
| `<Space><Space>f{c}` | 標記畫面所有 `c` 字元 |
| `<Space><Space>j` / `k` | 標記下方 / 上方行首 |
| `<Space><Space>/` | 標記搜尋結果 |

**何時用**：移動超過 5 行、或行內想跳到某字元但太遠按 `f` 不準時。

---

## 10. VSCode 整合的最佳實踐

### 原則
**讓 Vim 處理「文字編輯」，讓 VSCode 處理「IDE 功能」。**

| 該由 Vim 處理 | 該由 VSCode 處理 |
|---|---|
| 移動、選取、刪除、複製 | LSP（跳定義、重命名） |
| 替換、巨集、文字物件 | Debug、Run、測試 |
| 行內精準編輯 | 檔案總管、Git、終端 |

### 你已綁好的橋樑（Leader 系列）
- `<Space>r` rename ← LSP
- `<Space>a` quick fix ← LSP
- `<Space>g` / `<Space>G` 符號跳轉 ← LSP
- `<Space>/` 全域搜尋 ← VSCode
- `gd` / `gi` / `gy` / `gr` LSP 導覽
- `<Space>b` / `<Space>D` Debug

### 還給 VSCode 的快捷鍵
你已透過 `vim.handleKeys` 還原：`Ctrl+A/C/V/Z/Y/F/S/W/N/P`。這意味著：
- ✅ 在 commit message 框 `Ctrl+A` 真的全選
- ✅ `Ctrl+S` 永遠是存檔
- ⚠️ 失去 Vim 的 `<C-w>` 視窗指令（已用 `<C-h/j/k/l>` 替代）
- ⚠️ 失去 `<C-c>` 取消 Insert（用 `<Esc>` 或 `jj`）

---

## 11. 學習路徑建議

### 第 1 週：基礎肌肉記憶
**目標：不再用方向鍵。**
- `hjkl` 移動
- `i` `a` `o` 進 Insert，`<Esc>` 或 `jj` 出
- `w` `b` `e` 跳 word
- `0` `$` 行首尾
- `dd` 刪行、`yy` 複製、`p` 貼上、`u` undo、`<C-r>` redo

### 第 2 週：動詞 + 物件
**目標：開始用 `ciw` `da{` `yi"` 而不是「選取再操作」。**
- `c` `d` `y` + `iw` `aw` `i"` `i(` `i{`
- `f{c}` `t{c}` 行內跳字元
- `*` 搜尋游標下 word

### 第 3 週：你的個人化映射
**目標：把 cheatsheet 印出來，每次想滑鼠時看一眼。**
- `<Space>f` / `<Space>e` / `<Space>r` / `<Space>a`
- `gd` / `gr`
- `<Space>v` / `<Space>s` 分割
- `<C-h/j/k/l>` 切視窗

### 第 4 週以後
- Surround：`ysiw"` / `cs"'` / `ds(`
- Macros：先從錄製簡單 `qaq` 開始
- Registers：學會 `"+` 系統剪貼簿
- Easymotion：取代大跳

### 不要太早碰
- `<C-v>` 區塊選取（強大但難）
- 複雜的 `:g/pattern/d` 操作
- 自訂 plugin（VSCodeVim 不支援，先別管）

---

## 12. 常見踩雷與對策

### 雷 1：一直停在 Insert 模式
**症狀**：方向鍵移動、Esc 鍵都按到小指痛。
**解法**：強迫自己「打完一個小段就 `jj` 出來」。一週後肌肉記憶就形成。

### 雷 2：剛 yank 的東西被 `dd` 覆蓋
**症狀**：複製一段、刪一行、貼上，發現貼出來是被刪的那行。
**解法**：用 `"0p` 貼最近一次 yank；或刪用 `"_dd`。

### 雷 3：Leader 延遲讓 `f` `e` 變慢
**症狀**：按 `f` 想跳字元，要等 700ms 才反應。
**解法**：已設 `vim.timeout: 700`。若還是受不了，可考慮把 Leader 換成 `\` 或 `,`。

### 雷 4：`Ctrl+W` 想關 Tab 卻是 Vim window 指令
**症狀**：曾經發生。
**解法**：已在 `vim.handleKeys` 中還給 VSCode。

### 雷 5：`<C-i>` 跳轉行為不一致
**症狀**：以為跳到上次編輯位置，結果跳到別處。
**解法**：理解 Vim jumplist（**游標位置**歷史）≠ VSCode editor history（**檔案 / 編輯**歷史）。需要後者請從 Command Palette 找 "Navigate Back/Forward"。

### 雷 6：中文輸入法切換忘了切回英文（已自動處理）
**症狀**：在 Normal mode 按 `j` 跑出「ㄨ」。
**已自動化**：透過 `im-select.exe` + `vim.autoSwitchInputMethod` 達成：
- 離開 Insert mode → 自動切回英文 (`1033`)
- 進入 Insert mode → 自動還原上次的 IME（中文/英文）

**設定位置**：`vim.autoSwitchInputMethod` in settings.json
**Binary 位置**：`C:\Users\wenrong.huang\tools\im-select.exe`
**驗證**：開終端機跑 `~\tools\im-select.exe` 會印出當前 IME 代碼（1028=繁中, 1033=英文）

---

## 附錄：你的設定一覽

| 項目 | 設定 |
|---|---|
| Leader | `Space` |
| Easymotion | ✅ |
| Surround | ✅ |
| hlsearch / incsearch | ✅ |
| ignorecase + smartcase | ✅ |
| smartRelativeLine | ✅ |
| timeout | 700ms |
| `<C-o>` / `<C-i>` | Vim 原生 jumplist |
| 已還給 VSCode 的鍵 | `<C-a/c/v/z/y/f/s/w/n/p>` |

完整檔案：`%APPDATA%\Code\User\settings.json`
速查表：[vim-cheatsheet.md](./vim-cheatsheet.md)

---

_最後更新：2026-05-13_
_作者：個人化整理（基於 wenrong 的 VSCodeVim 設定）_

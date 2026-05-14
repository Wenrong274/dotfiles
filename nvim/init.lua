-- ============================================================
-- init.lua  (vscode-neovim primary, standalone fallback)
-- ============================================================

-- Leader = Space (must be set before any <leader> mapping AND lazy.nvim)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Base options (both modes)
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.clipboard = 'unnamedplus'    -- yank/delete -> system clipboard
vim.opt.timeoutlen = 700
vim.opt.scrolloff = 5
vim.opt.matchpairs:append('<:>')     -- % jumps in C# generics

-- Helper
local function map(mode, lhs, rhs, opts)
    opts = vim.tbl_extend('force', { silent = true, noremap = true }, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- ============================================================
-- lazy.nvim bootstrap
-- ============================================================
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        'git', 'clone', '--filter=blob:none', '--branch=stable',
        'https://github.com/folke/lazy.nvim.git', lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    -- Surround operations: ysiw" / cs"' / ds" / S in visual
    {
        'kylechui/nvim-surround',
        version = '*',
        event = 'VeryLazy',
        config = function() require('nvim-surround').setup({}) end,
    },
    -- Jump anywhere with 2 chars (replaces easymotion)
    {
        'folke/flash.nvim',
        event = 'VeryLazy',
        opts = {},
        keys = {
            { '<leader><leader>', mode = { 'n', 'x', 'o' },
              function() require('flash').jump() end, desc = 'Flash jump' },
        },
    },
    -- CamelCase motion: ,w / ,b / ,e jump within MyVariableName
    {
        'bkad/CamelCaseMotion',
        event = 'VeryLazy',
        init = function() vim.g.camelcasemotion_key = ',' end,
    },
}, {
    install = { missing = true },
    change_detection = { notify = false },
})

if vim.g.vscode then
    -- ====================================================
    -- VSCode integration
    -- ====================================================
    local function vs(name) return function() vim.fn.VSCodeNotify(name) end end

    -- Comments
    map('n', 'gcc', vs('editor.action.commentLine'))
    map('x', 'gc',  vs('editor.action.commentLine'))

    -- Whole-file text objects
    map('n', 'yae', 'ggVGy')
    map('n', 'dae', 'ggdG')
    map('n', 'vae', 'ggVG')

    -- LSP navigation
    map('n', 'gd', vs('editor.action.revealDefinition'))
    map('n', 'gi', vs('editor.action.goToImplementation'))
    map('n', 'gy', vs('editor.action.goToTypeDefinition'))
    map('n', 'gr', vs('editor.action.goToReferences'))
    map('n', ']e', vs('editor.action.marker.next'))
    map('n', '[e', vs('editor.action.marker.prev'))

    -- File / project
    map('n', '<leader>f', vs('workbench.action.quickOpen'))
    map('n', '<leader>e', vs('workbench.view.explorer'))

    -- Refactor / edit
    map('n', '<leader>r', vs('editor.action.rename'))
    map('n', '<leader>a', vs('editor.action.quickFix'))
    map('n', '<leader>o', vs('editor.action.organizeImports'))
    map('n', '<leader>c', vs('editor.action.formatDocument'))
    map('n', '<leader>n', vs('editor.action.insertSnippet'))

    -- Debug / test
    map('n', '<leader>b', vs('editor.debug.action.toggleBreakpoint'))
    map('n', '<leader>D', vs('workbench.action.debug.start'))
    map('n', '<leader>j', vs('workbench.action.debug.stepOver'))
    map('n', '<leader>i', vs('workbench.action.debug.stepInto'))
    map('n', '<leader>t', vs('testing.runAtCursor'))

    -- Search
    map('n', '<leader><CR>', ':nohlsearch<CR>')
    map('n', '<leader>/', vs('workbench.action.findInFiles'))
    map('n', '<leader>g', vs('workbench.action.gotoSymbol'))
    map('n', '<leader>G', vs('workbench.action.showAllSymbols'))

    -- Window split / focus
    map('n', '<leader>v', vs('workbench.action.splitEditor'))
    map('n', '<leader>s', vs('workbench.action.splitEditorDown'))
    map('n', '<C-h>',     vs('workbench.action.focusLeftGroup'))
    map('n', '<C-l>',     vs('workbench.action.focusRightGroup'))
    map('n', '<C-j>',     vs('workbench.action.focusBelowGroup'))
    map('n', '<C-k>',     vs('workbench.action.focusAboveGroup'))

    -- Tabs
    map('n', '<S-h>',     vs('workbench.action.previousEditor'))
    map('n', '<S-l>',     vs('workbench.action.nextEditor'))
    map('n', '<leader>w', vs('workbench.action.closeActiveEditor'))

    -- Text ops
    map('n', '<leader>S', vs('editor.action.sortLinesAscending'))

    -- Unity
    map('n', '<leader>U', vs('vstuc.attachUnityDebugger'))

    -- Visual indent keeps selection
    map('x', '<', '<gv')
    map('x', '>', '>gv')

    -- NOTE: jj/jk Esc handled by vscode-neovim.compositeKeys in settings.json
    -- (Insert mode is owned by VSCode, lua imap doesn't fire there)

    -- ----------------------------------------------------
    -- IME auto-switch via im-select.exe (Windows)
    -- ----------------------------------------------------
    local im_select = vim.fn.expand('$USERPROFILE') .. [[\tools\im-select.exe]]
    local default_im = '1033'   -- en-US
    local saved_im = default_im

    if vim.fn.filereadable(im_select) == 1 then
        vim.api.nvim_create_autocmd('InsertLeave', {
            callback = function()
                local current = vim.fn.system('"' .. im_select .. '"'):gsub('%s+', '')
                if current ~= '' then saved_im = current end
                vim.fn.system('"' .. im_select .. '" ' .. default_im)
            end,
        })
        vim.api.nvim_create_autocmd('InsertEnter', {
            callback = function()
                if saved_im ~= default_im then
                    vim.fn.system('"' .. im_select .. '" ' .. saved_im)
                end
            end,
        })
    end
else
    -- ====================================================
    -- Plain Neovim (standalone, from terminal)
    -- ====================================================
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.signcolumn = 'yes'
    vim.opt.termguicolors = true
end

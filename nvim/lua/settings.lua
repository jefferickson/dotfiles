-- leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- no mouse
vim.opt.mouse = ''

-- colors
vim.opt.termguicolors = true

-- keep fat cursor in insert mode
vim.opt.guicursor = ''

-- tabs and indents
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.nvim/undodir'
vim.opt.undofile = true

-- search
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- line numbers, visual spacing, and wrapping
vim.opt.scrolloff = 8
vim.opt.cmdheight = 2
vim.opt.foldcolumn = '1'
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.stal = 2

-- visual cues
vim.opt.showmatch = true
vim.opt.mat = 2
vim.opt.cursorline = true
vim.opt.cursorcolumn = true

-- color columns
vim.opt.colorcolumn = '79,119'

-- splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- location to pynvim
-- see :help g:python3_host_prog
vim.g.python3_host_prog = vim.fn.expand('$HOME/.pyenv/versions/py3nvim/bin/python')

-- return to last edit position on reopen
vim.api.nvim_create_augroup('settings', { clear = true })
vim.api.nvim_create_autocmd('BufReadPost', {
    group = 'settings',
    pattern = '*',
    callback = function()
        if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line('$') then
            vim.fn.setpos('.', vim.fn.getpos("'\""))
        end
    end
})

-- delete trailing whitespace on save
-- markdown uses two trailing spaces as a hard line break
vim.api.nvim_create_autocmd('BufWritePre', {
    group = 'settings',
    pattern = '*',
    callback = function(args)
        if vim.bo[args.buf].filetype == 'markdown' then
            return
        end
        local view = vim.fn.winsaveview()
        vim.cmd([[silent! keeppatterns %s/\s\+$//e]])
        vim.fn.winrestview(view)
    end
})

-- delete empty lines at end of file on save
vim.api.nvim_create_autocmd('BufWritePre', {
    group = 'settings',
    pattern = '*',
    callback = function()
        local view = vim.fn.winsaveview()
        vim.cmd([[silent! keeppatterns %s/\($\n\s*\)\+\%$//]])
        vim.fn.winrestview(view)
    end
})

-- two-space indent for JS and TS, including JSX and TSX
vim.api.nvim_create_autocmd('FileType', {
    group = 'settings',
    pattern = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.shiftwidth = 2
    end
})

-- Go uses tabs. The runtime ftplugin does not set this.
vim.api.nvim_create_autocmd('FileType', {
    group = 'settings',
    pattern = 'go',
    callback = function()
        vim.opt_local.expandtab = false
        vim.opt_local.tabstop = 4
        vim.opt_local.softtabstop = 4
        vim.opt_local.shiftwidth = 4
    end
})

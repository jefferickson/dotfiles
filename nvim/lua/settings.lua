-- leader key
vim.g.mapleader = ' '

-- colors
vim.opt.termguicolors = true

-- keep fat cursor in insert mode
vim.opt.guicursor = ''

-- tabs and indents
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.smartindent = true

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

-- performance
vim.opt.lazyredraw = true

-- visual cues
vim.opt.showmatch = true
vim.opt.mat = 2
vim.opt.cursorline = true
vim.opt.cursorcolumn = true

-- color columns
local colorcolumns = '79'
for i = 119, 250 do
    colorcolumns = colorcolumns .. ',' .. tostring(i)
end
vim.opt.colorcolumn = colorcolumns

-- splits
vim.opt.splitright = true
vim.opt.splitbelow = true

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
vim.api.nvim_create_autocmd('BufWritePre', {
    group = 'settings',
    pattern = '*',
    callback = function()
        local saveCursor = vim.fn.getpos('.')
        local oldQuery = vim.fn.getreg('/')
        vim.cmd([[ silent! %s/\s\+$//e ]])
        vim.fn.setpos('.', saveCursor)
        vim.fn.setreg('/', oldQuery)
    end
})

-- delete empty lines at end of file on save
vim.api.nvim_create_autocmd('BufWritePre', {
    group = 'settings',
    pattern = '*',
    callback = function()
        local saveCursor = vim.fn.getpos('.')
        vim.cmd([[ silent! %s/\($\n\s*\)\+\%$// ]])
        vim.fn.setpos('.', saveCursor)
    end
})

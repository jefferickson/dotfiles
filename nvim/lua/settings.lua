-- leader key
vim.g.mapleader = ' '

-- keep fat cursor in insert mode
vim.opt.guicursor = ''

-- line numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- tabs
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.nvim/undodir"
vim.opt.undofile = true

-- search highlighting
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- top/bottom line spacing
vim.opt.scrolloff = 8

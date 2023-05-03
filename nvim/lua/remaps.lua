-- move blocks of code
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- keep cursor in place at various times
vim.keymap.set("n", "J", "mzJ`z")
-- TODO : check these
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "∆", "<C-e>")
vim.keymap.set("n", "˚", "<C-y>")
vim.keymap.set("n", "0", "^")

-- easily turn off search highlighting
vim.keymap.set("n", "<leader><cr>", ":noh<cr>")

-- toggle paste mode
vim.keymap.set("", "<leader>pp", ":setlocal paste!<cr>")

-- use arrow keys for nav in normal mode
vim.keymap.set("n", "<Up>", "<C-o>")
vim.keymap.set("n", "<Down>", "<C-i>")
vim.keymap.set("n", "<Left>", ":bprev<cr>")
vim.keymap.set("n", "<Right>", ":bnext<cr>")
vim.keymap.set("n", "<PageUp>", "<C-u>")
vim.keymap.set("n", "<PageDown>", "<C-d>")

-- fzf fuzzy find files
vim.keymap.set("n", "<leader>f", "<cmd>lua require('fzf-lua').git_files()<CR>", { silent = true })

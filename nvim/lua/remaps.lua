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

-- TODO: can we move special paste here from karabiner

-- fzf fuzzy find files
vim.keymap.set("n", "<leader>f", "<cmd>lua require('fzf-lua').git_files()<CR>", { silent = true })

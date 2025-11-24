-- better cursor control
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', '<C-j>', '<C-e>')
vim.keymap.set('n', '<C-k>', '<C-y>')
vim.keymap.set('i', '<C-j>', '<esc><C-e>li')
vim.keymap.set('i', '<C-k>', '<esc><C-y>li')
vim.keymap.set('n', '0', '0^')
vim.keymap.set('n', '^', '0')
vim.keymap.set('n', 'gg', 'gg0^')
vim.keymap.set('n', 'G', 'G0^')
vim.keymap.set('n', '<TAB>', '<C-w>w')
vim.keymap.set('n', '{', ':<C-u>execute "keepjumps norm! " . v:count1 . "{"<CR>', { silent = true })
vim.keymap.set('n', '}', ':<C-u>execute "keepjumps norm! " . v:count1 . "}"<CR>', { silent = true })
vim.keymap.set('i', '<C-space>', '<esc>ddkA')

-- better file navigation
vim.keymap.set('n', '<Up>', '<C-o>')
vim.keymap.set('n', '<Down>', '<C-i>')
vim.keymap.set('n', '<Left>', ':bprev<cr>')
vim.keymap.set('n', '<Right>', ':bnext<cr>')
vim.keymap.set('n', '<PageUp>', '<C-u>zz')
vim.keymap.set('n', '<PageDown>', '<C-d>zz')
vim.keymap.set('n', 'U', '<C-u>zz')
vim.keymap.set('n', 'D', '<C-d>zz')

-- move blocks of code
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")
vim.keymap.set('n', 'J', 'mzJ`z')

-- easily turn off search highlighting
vim.keymap.set('n', '<leader><cr>', ':noh<cr>')

-- toggle paste mode
vim.keymap.set('', '<leader>pp', ':setlocal paste!<cr>')

-- better integration with karabiner mods
-- shift becomes z<cr>
vim.keymap.set('n', '<C-r>', 'z<cr>')
vim.keymap.set('n', '<leader>r', '<C-r>')

-- fzf fuzzy find files
vim.keymap.set('n', '<leader>f', '<cmd>lua require("fzf-lua").git_files()<CR>', { silent = true })

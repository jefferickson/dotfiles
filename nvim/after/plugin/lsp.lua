local lsp = require('lsp-zero')
local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()
local cmp_format = lsp.cmp_format()
local cmp_select_opts = { behavior = cmp.SelectBehavior.Select }

lsp.on_attach(function(client, bufnr)
    lsp.default_keymaps({ buffer = bufnr })
end)

require('mason').setup({})
require('mason-lspconfig').setup({
    ensure_installed = { 'lua_ls', 'pyright', 'ts_ls', 'bashls', 'tailwindcss',
        'dockerls', 'elixirls', 'elmls', 'gopls', 'html', 'jsonls', 'marksman',
        'r_language_server', 'rust_analyzer', 'sqls', 'tflint', 'vimls',
        'yamlls',
    },

    handlers = {
        lsp.default_setup,
        lua_ls = function()
            local lua_opts = lsp.nvim_lua_ls()
            require('lspconfig').lua_ls.setup(lua_opts)
        end,
    }
})

require('lspconfig').ts_ls.setup({
    init_options = {
        preferences = {
            disableSuggestions = true,
        },
    },
})

cmp.setup({
    formatting = cmp_format,
    preselect = 'item',
    completion = {
        autocomplete = false,
        completeopt = 'menu,menuone,noinsert'
    },
    mapping = cmp.mapping.preset.insert({
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<TAB>'] = cmp_action.luasnip_supertab(),
        ['j'] = cmp.mapping.select_next_item(cmp_select_opts),
        ['k'] = cmp.mapping.select_prev_item(cmp_select_opts),
    }),
})

vim.diagnostic.config({ virtual_text = false })

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>a', '<cmd>lua vim.diagnostic.setqflist()<CR> <C-w>k', { silent = true })
vim.keymap.set('n', '<leader>w', '<cmd>w<CR> <cmd>lua vim.diagnostic.setqflist()<CR> <C-w>k k', { silent = true })
vim.keymap.set('n', '<leader>o', '<cmd>on<CR>', { silent = true })
vim.keymap.set('n', 'gd', 'gd z<CR>', { silent = true })

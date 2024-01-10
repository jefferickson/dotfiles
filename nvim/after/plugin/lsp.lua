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
    ensure_installed = {},
    handlers = {
        lsp.default_setup,
        lua_ls = function()
            local lua_opts = lsp.nvim_lua_ls()
            require('lspconfig').lua_ls.setup(lua_opts)
        end,
    }
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

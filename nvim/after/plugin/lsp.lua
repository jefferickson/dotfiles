local lsp = require('lsp-zero').preset({})
local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()
local cmp_select_opts = { behavior = cmp.SelectBehavior.Select }

lsp.ensure_installed({
})

lsp.on_attach(function(_, bufnr)
    lsp.default_keymaps({ buffer = bufnr })
end)

require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())

lsp.setup()

cmp.setup({
    preselect = 'item',
    completion = {
        autocomplete = false,
        completeopt = 'menu,menuone,noinsert'
    },
    mapping = {
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<TAB>'] = cmp_action.luasnip_supertab(),
        ['j'] = cmp.mapping.select_next_item(cmp_select_opts),
        ['k'] = cmp.mapping.select_prev_item(cmp_select_opts),
    },
})

vim.diagnostic.config({ virtual_text = false })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)

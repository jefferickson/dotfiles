local lsp = require('lsp-zero').preset({})
local cmp = require('cmp')
local cmp_select_opts = {behavior = cmp.SelectBehavior.Select}

lsp.ensure_installed({
})

lsp.on_attach(function(client, bufnr)
    lsp.default_keymaps({buffer = bufnr})
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
        ['<CR>'] = cmp.mapping.confirm({select = true}),
        ['<TAB>'] = cmp.mapping.complete(),
        ['j'] = cmp.mapping.select_next_item(cmp_select_opts),
        ['k'] = cmp.mapping.select_prev_item(cmp_select_opts),
    },
})

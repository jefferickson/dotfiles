return {
    'mason-org/mason-lspconfig.nvim',
    dependencies = {
        'mason-org/mason.nvim',
        'neovim/nvim-lspconfig',
        'hrsh7th/nvim-cmp',
        'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
        local cmp = require('cmp')
        local cmp_select_opts = { behavior = cmp.SelectBehavior.Select }

        vim.lsp.config('*', {
            capabilities = require('cmp_nvim_lsp').default_capabilities(),
        })

        require('mason').setup({})
        require('mason-lspconfig').setup {
            ensure_installed = {
                'autotools_ls', 'bashls', 'clangd', 'cssls', 'dockerls', 'elixirls',
                'elmls', 'gopls', 'html', 'jsonls', 'lua_ls', 'marksman', 'pyright',
                'r_language_server', 'rust_analyzer', 'sqls', 'tailwindcss', 'tflint',
                'ts_ls', 'vimls', 'yamlls',
            },
        }

        vim.lsp.config('lua_ls', {
            settings = {
                Lua = {
                    runtime = { version = 'LuaJIT' },
                    workspace = {
                        checkThirdParty = false,
                        library = { vim.env.VIMRUNTIME },
                    },
                },
            },
        })

        vim.lsp.config('ts_ls', {
            init_options = {
                preferences = {
                    disableSuggestions = true,
                },
            },
        })

        -- Ships with the gleam compiler (`gleam lsp`). Mason no longer packages it.
        vim.lsp.enable('gleam')

        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(event)
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = event.buf, desc = 'Go to definition' })
            end,
        })

        cmp.setup({
            formatting = {
                fields = { 'abbr', 'menu', 'kind' },
                format = function(entry, item)
                    local source = entry.source.name
                    item.menu = source == 'nvim_lsp' and '[LSP]' or string.format('[%s]', source)
                    return item
                end,
            },
            snippet = {
                expand = function(args)
                    vim.snippet.expand(args.body)
                end,
            },
            sources = {
                { name = 'nvim_lsp' },
            },
            preselect = 'item',
            window = {
                completion = cmp.config.window.bordered({ border = 'rounded' }),
                documentation = cmp.config.window.bordered({ border = 'rounded' }),
            },
            completion = {
                autocomplete = false,
                completeopt = 'menu,menuone,noinsert',
            },
            mapping = cmp.mapping.preset.insert({
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
                ['<Tab>'] = cmp.mapping(function(fallback)
                    local col = vim.fn.col('.') - 1

                    if cmp.visible() then
                        cmp.select_next_item(cmp_select_opts)
                    elseif vim.snippet.active({ direction = 1 }) then
                        vim.snippet.jump(1)
                    elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                        fallback()
                    else
                        cmp.complete()
                    end
                end, { 'i', 's' }),
                ['j'] = cmp.mapping.select_next_item(cmp_select_opts),
                ['k'] = cmp.mapping.select_prev_item(cmp_select_opts),
            }),
        })

        vim.diagnostic.config({ virtual_text = false })
    end,
}

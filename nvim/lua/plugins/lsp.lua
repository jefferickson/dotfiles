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
        require('mason-lspconfig').setup({
            ensure_installed = {
                'autotools_ls',
                'bashls',
                'clangd',
                'cssls',
                'dockerls',
                'elixirls',
                'elmls',
                'gopls',
                'html',
                'jsonls',
                'lua_ls',
                'marksman',
                'pyright',
                'ruff',
                'r_language_server',
                'rust_analyzer',
                'sqls',
                'tailwindcss',
                'tflint',
                'ts_ls',
                'vimls',
                'yamlls',
            },
        })

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

        -- Ruff sorts imports on save. Keep Pyright from doing it too.
        vim.lsp.config('pyright', {
            settings = {
                pyright = {
                    disableOrganizeImports = true,
                },
            },
        })

        -- Use ruff version pinned in the project venv.
        local function project_ruff_bin()
            local name = vim.api.nvim_buf_get_name(0)
            local dir = name ~= '' and vim.fs.dirname(name) or vim.uv.cwd()
            local git_root = vim.fs.root(dir, '.git')

            while dir do
                for _, rel in ipairs({ '.venv/bin/ruff', 'venv/bin/ruff' }) do
                    local candidate = vim.fs.joinpath(dir, rel)
                    if vim.uv.fs_stat(candidate) then
                        return candidate
                    end
                end
                if git_root and dir == git_root then
                    break
                end
                local parent = vim.fs.dirname(dir)
                if not parent or parent == dir then
                    break
                end
                dir = parent
            end
        end

        vim.lsp.config('ruff', {
            cmd = function(dispatchers)
                return vim.lsp.rpc.start({ project_ruff_bin() or 'ruff', 'server' }, dispatchers)
            end,
            init_options = {
                settings = {
                    configurationPreference = 'filesystemFirst',
                },
            },
        })

        -- Ships with the gleam compiler (`gleam lsp`). Mason no longer packages it.
        vim.lsp.enable('gleam')

        local function apply_ruff_source_action(client, bufnr, kind)
            local last_line = math.max(vim.api.nvim_buf_line_count(bufnr) - 1, 0)
            local last_text = vim.api.nvim_buf_get_lines(bufnr, last_line, last_line + 1, true)[1] or ''
            local response = client:request_sync('textDocument/codeAction', {
                textDocument = vim.lsp.util.make_text_document_params(bufnr),
                range = {
                    start = { line = 0, character = 0 },
                    ['end'] = { line = last_line, character = vim.str_utfindex(last_text, client.offset_encoding) },
                },
                context = {
                    diagnostics = {},
                    only = { kind },
                    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
                },
            }, 1000, bufnr)

            if not response or response.err or type(response.result) ~= 'table' then
                return
            end

            local provider = client.server_capabilities.codeActionProvider
            local can_resolve = type(provider) == 'table' and provider.resolveProvider

            for _, action in ipairs(response.result) do
                if not action.disabled then
                    local edit = action.edit
                    if not edit and can_resolve then
                        local resolved = client:request_sync('codeAction/resolve', action, 1000, bufnr)
                        edit = resolved and not resolved.err and resolved.result and resolved.result.edit
                    end
                    if edit then
                        vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding)
                    end
                end
            end
        end

        vim.api.nvim_create_augroup('lsp', { clear = true })
        vim.api.nvim_create_autocmd('LspAttach', {
            group = 'lsp',
            callback = function(event)
                local client = vim.lsp.get_client_by_id(event.data.client_id)
                if client and client.name == 'ruff' then
                    -- Pyright owns hover.
                    client.server_capabilities.hoverProvider = false
                end

                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = event.buf, desc = 'Go to definition' })
            end,
        })

        vim.api.nvim_create_autocmd('BufWritePre', {
            group = 'lsp',
            callback = function(args)
                if vim.bo[args.buf].filetype ~= 'python' then
                    return
                end

                local client = vim.lsp.get_clients({ bufnr = args.buf, name = 'ruff' })[1]
                if not client then
                    return
                end

                local view = vim.fn.winsaveview()
                for _, kind in ipairs({ 'source.organizeImports', 'source.fixAll' }) do
                    apply_ruff_source_action(client, args.buf, kind)
                end
                vim.lsp.buf.format({
                    bufnr = args.buf,
                    async = false,
                    timeout_ms = 1000,
                    filter = function(format_client)
                        return format_client.name == 'ruff'
                    end,
                })
                if vim.api.nvim_get_current_buf() == args.buf then
                    vim.fn.winrestview(view)
                end
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

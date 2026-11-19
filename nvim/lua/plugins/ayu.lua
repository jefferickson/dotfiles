return {
    'Shatur/neovim-ayu',
    config = function()
        local accent = '#FFCC66'
        local customBg = '#262626'
        local customColumn = '#303030'
        local customFunction = '#FFEF7F'
        local customLineNrBg = '#1F1F1F'
        local customLineNrFg = '#4D4D4D'
        local customSelection = '#444444'
        local customSelectionBright = '#666666'
        local customGreyWhite = '#CBCCC6'
        local customWhite = '#D9D7CD'
        local diagWarning = '#4D3300'

        local colors = require('ayu.colors')
        colors.generate(true)

        require('ayu').setup({

            mirage = true,
            overrides = {
                ColorColumn = { bg = customColumn },
                CursorColumn = { bg = customColumn },
                CursorLine = { bg = customColumn },
                CursorLineNr = { fg = accent, bg = customColumn },
                FoldColumn = { bg = customLineNrBg },
                IncSearch = { fg = colors.bg, bg = colors.special },
                LineNr = { fg = customLineNrFg, bg = customLineNrBg },
                Normal = { bg = customBg },
                SignColumn = { bg = customBg },
                TabLine = { fg = customGreyWhite, bg = customSelection },
                TabLineFill = { bg = customSelection },
                TabLineSel = { fg = customGreyWhite, bg = customSelectionBright },
                Visual = { bg = customSelection },

                -- Treesitter
                ['@function'] = { fg = customFunction },
                ['@function.method'] = { fg = customFunction },
                ['@module'] = { fg = customFunction },
                ['@variable'] = { fg = customWhite },
                ['@variable.builtin'] = { fg = customFunction },
            },
        })

        require('ayu').colorscheme()

        -- Override FoldColumn only in windows whose buffer has diagnostics.
        -- Namespace -1 clears the window override so other windows keep the
        -- colorscheme color. 0 is the global namespace, not "unset".
        local diag_ns = vim.api.nvim_create_namespace('diagfold')
        vim.api.nvim_set_hl(diag_ns, 'FoldColumn', { bg = diagWarning })

        local diag_severities = {
            vim.diagnostic.severity.ERROR,
            vim.diagnostic.severity.WARN,
            vim.diagnostic.severity.HINT,
        }

        local function sync_diag_fold(win)
            local buf = vim.api.nvim_win_get_buf(win)
            local has_diagnostics = #vim.diagnostic.get(buf, { severity = diag_severities }) > 0
            vim.api.nvim_win_set_hl_ns(win, has_diagnostics and diag_ns or -1)
        end

        vim.api.nvim_create_augroup('ayu', { clear = true })
        vim.api.nvim_create_autocmd('DiagnosticChanged', {
            group = 'ayu',
            callback = function(args)
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    if vim.api.nvim_win_get_buf(win) == args.buf then
                        sync_diag_fold(win)
                    end
                end
            end,
        })

        vim.api.nvim_create_autocmd('BufWinEnter', {
            group = 'ayu',
            callback = function()
                sync_diag_fold(vim.api.nvim_get_current_win())
            end,
        })

        for _, win in ipairs(vim.api.nvim_list_wins()) do
            sync_diag_fold(win)
        end
    end,
}

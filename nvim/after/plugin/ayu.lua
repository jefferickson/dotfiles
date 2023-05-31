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

require('ayu').setup({
    mirage = true,
    overrides = {
        ColorColumn = { bg = customColumn },
        CursorColumn = { bg = customColumn },
        CursorLine = { bg = customColumn },
        CursorLineNr = { fg = accent, bg = customColumn },
        FoldColumn = { bg = customLineNrBg },
        LineNr = { fg = customLineNrFg, bg = customLineNrBg },
        Normal = { bg = customBg },
        SignColumn = { bg = customBg },
        TabLine = { fg = customGreyWhite, bg = customSelection },
        TabLineFill = { bg = customSelection },
        TabLineSel = { fg = customGreyWhite, bg = customSelectionBright },
        Visual = { bg = customSelection },

        -- Treesitter
        ['@function'] = { fg = customFunction },
        ['@method'] = { fg = customFunction },
        ['@namespace'] = { fg = customFunction },
        ['@variable'] = { fg = customWhite },
        ['@variable.builtin'] = { fg = customFunction },
    }
})

require('ayu').colorscheme()

vim.diagnostic.handlers['my/diagcolumn'] = {
    show = function()
        vim.api.nvim_set_hl(0, 'FoldColumn', { bg = diagWarning })
    end,
    hide = function()
        vim.api.nvim_set_hl(0, 'FoldColumn', { bg = customLineNrBg })
    end,
}

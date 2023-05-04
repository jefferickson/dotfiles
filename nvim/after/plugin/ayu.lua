local accent = '#FFCC66'
local customBg = '#262626'
local customColumn = '#303030'
local customLineNrBg = '#1F1F1F'
local customLineNrFg = '#4D4D4D'
local customSelection = '#444444'
local customSelectionBright = '#666666'
local customWhite = '#CBCCC6'

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
        TabLine = { fg = customWhite, bg = customSelection },
        TabLineFill = { bg = customSelection },
        TabLineSel = { fg = fakeWhite, bg = customSelectionBright },
        Visual = { bg = customSelection },
    }
})

require('ayu').colorscheme()

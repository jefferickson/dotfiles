require('ayu').setup({
    mirage = true,
    overrides = {
        Normal = { bg = '#262626' },
        Function = { fg = '#FFEF7F' },
    }
})

require('ayu').colorscheme()

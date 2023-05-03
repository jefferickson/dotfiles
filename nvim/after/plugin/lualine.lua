local custom_theme = require'lualine.themes.ayu_mirage'
custom_theme.visual.a.gui = ''
custom_theme.replace.a.gui = ''
custom_theme.inactive.a.gui = ''
custom_theme.normal.a.gui = ''
custom_theme.insert.a.gui = ''

require('lualine').setup {
    options = {
        icons_enabled = false,
        theme = custom_theme,
        component_separators = {},
        section_separators = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
        }
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'fileformat', 'encoding', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
    }
}

return {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'MunifTanjim/nui.nvim',
    },
    config = function()
        require('neo-tree').setup {
            close_if_last_window = true,

            filesystem = {
                filtered_items = {
                    hide_dotfiles = false
                }
            },

            window = {
                position = 'right'
            }
        }
    end,
}

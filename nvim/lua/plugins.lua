vim.cmd.packadd('packer.nvim')

return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    use 'airblade/vim-gitgutter'
    use 'ibhagwan/fzf-lua'
    use 'mechatroner/rainbow_csv'
    use 'nvim-lualine/lualine.nvim'
    use 'ruanyl/vim-gh-line'
    use 'Shatur/neovim-ayu'
    use 'terryma/vim-expand-region'
    use 'tpope/vim-commentary'

    vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])
    use {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v2.x",
        requires = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
        },
    }

    use {
        'nvim-treesitter/nvim-treesitter',
        run = function()
            local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
            ts_update()
        end,
    }

    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v2.x',
        requires = {
            {'neovim/nvim-lspconfig'},
            {
                'williamboman/mason.nvim',
                run = function()
                    pcall(vim.cmd, 'MasonUpdate')
                end,
            },
            {'williamboman/mason-lspconfig.nvim'},
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'L3MON4D3/LuaSnip'},
        },
    }

end)

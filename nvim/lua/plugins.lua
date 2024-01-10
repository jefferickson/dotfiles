require('lazy').setup({

    'ibhagwan/fzf-lua',
    'lewis6991/gitsigns.nvim',
    'mechatroner/rainbow_csv',
    'nvim-lualine/lualine.nvim',
    'ruanyl/vim-gh-line',
    'Shatur/neovim-ayu',
    'terryma/vim-expand-region',
    'tpope/vim-commentary',

    {
        'nvim-neo-tree/neo-tree.nvim',
        branch = 'v3.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'MunifTanjim/nui.nvim'
        }
    },

    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate'
    },

    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        dependencies = {
            {'williamboman/mason.nvim'},
            {'williamboman/mason-lspconfig.nvim'},
            {'neovim/nvim-lspconfig'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'hrsh7th/nvim-cmp'},
            {'L3MON4D3/LuaSnip'}
        }
    }

})

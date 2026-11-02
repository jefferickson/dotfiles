require('lazy').setup {

    spec = {

        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/nvim-cmp',
        'ibhagwan/fzf-lua',
        'lewis6991/gitsigns.nvim',
        'mason-org/mason.nvim',
        'mason-org/mason-lspconfig.nvim',
        'mechatroner/rainbow_csv',
        'neovim/nvim-lspconfig',
        'nvim-lualine/lualine.nvim',
        'ruanyl/vim-gh-line',
        'Shatur/neovim-ayu',
        'terryma/vim-expand-region',
        'tpope/vim-commentary',
        'tpope/vim-surround',
        'wellle/context.vim',

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
            branch = 'main',
            lazy = false,
            build = ':TSUpdate',
        },

    },
    install = { missing = true },
    checker = { enabled = true },

}

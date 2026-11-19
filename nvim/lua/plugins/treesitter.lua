return {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
        require('nvim-treesitter').install {
            'bash', 'c', 'cpp', 'css', 'csv', 'dockerfile', 'eex', 'elixir', 'elm',
            'gleam', 'go', 'gomod', 'gotmpl', 'gowork', 'heex', 'html', 'javascript',
            'json', 'lua', 'make', 'markdown', 'python', 'r', 'rust', 'scss', 'sql',
            'surface', 'terraform', 'tsx', 'typescript', 'vim', 'yaml',
        }

        vim.api.nvim_create_autocmd('FileType', {
            callback = function()
                pcall(vim.treesitter.start)
            end,
        })
    end,
}

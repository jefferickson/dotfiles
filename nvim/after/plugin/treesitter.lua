require('nvim-treesitter').install {
    'c', 'lua', 'vim', 'markdown', 'bash', 'css', 'csv',
    'dockerfile', 'elixir', 'elm', 'gleam', 'go', 'html', 'javascript', 'json',
    'make', 'python', 'r', 'rust', 'sql', 'terraform', 'typescript', 'yaml'
}

vim.api.nvim_create_autocmd('FileType', {
    callback = function()
        pcall(vim.treesitter.start)
    end,
})

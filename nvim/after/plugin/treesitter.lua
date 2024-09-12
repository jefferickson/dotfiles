require('nvim-treesitter.configs').setup({
    ensure_installed = { 'c', 'lua', 'vim', 'markdown', 'bash', 'css', 'csv',
        'dockerfile', 'elixir', 'elm', 'go', 'html', 'javascript', 'json',
        'make', 'python', 'r', 'rust', 'sql', 'terraform', 'typescript', 'yaml',
    },

    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    }
})

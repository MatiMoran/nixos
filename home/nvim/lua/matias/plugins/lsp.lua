return {
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        dependencies = {
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'neovim/nvim-lspconfig',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/nvim-cmp',
            'L3MON4D3/LuaSnip',
        },
        config = function()

            -- This is for adding support for codeium
            local cmp = require('cmp')
            local cmp_format = require('lsp-zero').cmp_format({details = true})

            cmp.setup({
                sources = {
                    {name = 'codeium'},
                    {name = 'nvim_lsp'},
                    {name = 'copilot'},
                },
                --- (Optional) Show source name in completion menu
                formatting = cmp_format,
            })


            -- This is the normal config of LSP
            local lsp_zero = require('lsp-zero')

            lsp_zero.on_attach(function(client, bufnr)
                -- see :help lsp-zero-keybindings
                -- to learn the available actions
                lsp_zero.default_keymaps({buffer = bufnr})
            end)

            require('mason').setup({})
            require('mason-lspconfig').setup({
                ensure_installed = { "clangd" },
                handlers = {
                    lsp_zero.default_setup,
                },
            })
        end,
    },
}

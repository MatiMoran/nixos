return {
    {
        'williamboman/mason.nvim',
        dependencies = {
            'williamboman/mason-lspconfig.nvim',
            'neovim/nvim-lspconfig',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/nvim-cmp',
            'L3MON4D3/LuaSnip',
        },
        config = function()
            local cmp = require('cmp')
            cmp.setup({
                sources = {
                    { name = 'codeium' },
                    { name = 'nvim_lsp' },
                    { name = 'copilot' },
                },
                mapping = cmp.mapping.preset.insert({}),
            })

            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(ev)
                    local buf = ev.buf
                    vim.keymap.set('n', 'K',    vim.lsp.buf.hover,           { buffer = buf })
                    vim.keymap.set('n', 'gd',   vim.lsp.buf.definition,      { buffer = buf })
                    vim.keymap.set('n', 'gD',   vim.lsp.buf.declaration,     { buffer = buf })
                    vim.keymap.set('n', 'gi',   vim.lsp.buf.implementation,  { buffer = buf })
                    vim.keymap.set('n', 'go',   vim.lsp.buf.type_definition, { buffer = buf })
                    vim.keymap.set('n', 'gr',   vim.lsp.buf.references,      { buffer = buf })
                    vim.keymap.set('n', 'gs',   vim.lsp.buf.signature_help,  { buffer = buf })
                    vim.keymap.set('n', '<F2>', vim.lsp.buf.rename,          { buffer = buf })
                    vim.keymap.set('n', '<F4>', vim.lsp.buf.code_action,     { buffer = buf })
                    vim.keymap.set('n', 'gl',   vim.diagnostic.open_float,   { buffer = buf })
                    vim.keymap.set('n', '[d',   vim.diagnostic.goto_prev,    { buffer = buf })
                    vim.keymap.set('n', ']d',   vim.diagnostic.goto_next,    { buffer = buf })
                end,
            })

            local capabilities = require('cmp_nvim_lsp').default_capabilities()
            capabilities.workspace = capabilities.workspace or {}
            capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = true }

            require('mason').setup({})
            require('mason-lspconfig').setup({
                ensure_installed = { 'clangd', 'pyright' },
                handlers = {
                    function(server_name)
                        require('lspconfig')[server_name].setup({
                            capabilities = capabilities,
                        })
                    end,
                },
            })
        end,
    },
}

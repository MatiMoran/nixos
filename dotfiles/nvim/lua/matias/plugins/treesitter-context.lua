return {
    'nvim-treesitter/nvim-treesitter-context',
    opts = {
        on_attach = function(buf)
            return vim.bo[buf].filetype ~= 'markdown'
        end,
    },
}

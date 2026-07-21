local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.autoindent = true
opt.expandtab = true

opt.smartindent = true

opt.wrap = false

opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true

opt.hlsearch = false
opt.incsearch = true

opt.termguicolors = true

opt.scrolloff = 16

opt.updatetime = 50

opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    pattern = "*",
    callback = function()
        if vim.fn.mode() ~= "c" then
            vim.cmd("checktime")
        end
    end,
})

local lsp_restart_timer = nil

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "FileChangedShellPost" }, {
    pattern = "*",
    callback = function()
        if vim.bo.buftype ~= "" or vim.bo.filetype == "" or vim.bo.filetype == "NvimTree" then
            return
        end

        if lsp_restart_timer then
            lsp_restart_timer:stop()
            lsp_restart_timer:close()
            lsp_restart_timer = nil
        end

        lsp_restart_timer = vim.defer_fn(function()
            lsp_restart_timer = nil
            vim.cmd("LspRestart")
        end, 300)
    end,
})

-- disabled to nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

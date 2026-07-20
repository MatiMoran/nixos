vim.g.mapleader = " "

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '>-2<CR>gv=gv")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- copy to pc clipboard
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])

-- paste from pc clipboard
vim.keymap.set({"n", "v"}, "<leader>p", [["+p]])

-- visual mode: paste sin sobrescribir el register
vim.keymap.set("x", "p", '"_dP')

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>.", vim.lsp.buf.code_action)

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("source $MYVIMRC")
end)

-- quickfix list
vim.keymap.set('n', ']q', '<cmd>cnext<CR>zz')
vim.keymap.set('n', ']l', '<cmd>cprev<CR>zz')

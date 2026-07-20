return {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make"
            },
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")

            telescope.setup {
                defaults = {
                    hidden = true,
                    file_ignore_patterns = { "%.git/", "%.mypy_cache/", "%.venv/", "__pycache__/" },
                    tiebreak = function(current_entry, existing_entry, _prompt)
                        local function is_test(path)
                            return path:match("^tests?/") ~= nil
                                or path:match("/tests?/") ~= nil
                                or path:match("_test%.") ~= nil
                        end
                        local curr_is_test  = is_test(current_entry.ordinal  or "")
                        local exist_is_test = is_test(existing_entry.ordinal or "")
                        if curr_is_test == exist_is_test then return false end
                        return not curr_is_test
                    end,
                },
                extensions = {
                    fzf = {
                        fuzzy = true,                    -- false will only do exact matching
                        override_generic_sorter = true,  -- override the generic sorter
                        override_file_sorter = true,     -- override the file sorter
                        case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                    }
                }
            }

            telescope.load_extension("fzf")

            -- keymaps
            local keymaps = vim.keymap

            keymaps.set("n", "<leader>ps", function()
                builtin.grep_string({ search = vim.fn.input("Grep > ") });
            end)

            keymaps.set("n", "<leader>pf", function()
                builtin.find_files({ no_ignore = true, hidden = true });
            end)

            keymaps.set("n", "<C-p>", function()
                builtin.find_files({ no_ignore = true, hidden = true });
            end)
        end,
    }
}

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
-- Function to toggle diagnostics
local function toggle_diagnostics()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end
vim.keymap.set('n', '<leader>td', toggle_diagnostics, { desc = 'Toggle [D]iagnostic' })

-- Set the keymap
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands

-- vim.keymap.set('n', '<CR>', 'm`o<Esc>``')
-- vim.keymap.set('n', '<S-CR>', 'm`O<Esc>``')

-- Add auto-pairs
vim.keymap.set('i', '"', '""<left>', { expr = false })
vim.keymap.set('i', "'", "''<left>", { expr = false })
vim.keymap.set('i', '(', '()<left>', { expr = false })
vim.keymap.set('i', '[', '[]<left>', { expr = false })
vim.keymap.set('i', '{', '{}<left>', { expr = false })
vim.keymap.set('i', '{<CR>', '{<CR>}<Esc>O', { expr = false })
vim.keymap.set('i', '`', '``<left>', { expr = false })

-- paste in visual mode without overwriting the default register
vim.keymap.set('v', 'p', '"_dP', { expr = false })

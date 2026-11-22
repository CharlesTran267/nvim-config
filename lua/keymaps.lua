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

-- No Esc-based terminal-mode exit: nvim decodes two Esc presses under 'ttimeoutlen'
-- (50ms) apart as <M-Esc>, so a fast Esc-Esc meant for Claude (rewind) or Codex
-- (edit previous) dropped into terminal-normal. Use <C-\><C-n> or <A-v>.
vim.keymap.set('t', '<A-v>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands

-- vim.keymap.set('n', '<CR>', 'm`o<Esc>``')
-- vim.keymap.set('n', '<S-CR>', 'm`O<Esc>``')

-- paste in visual mode without overwriting the default register
vim.keymap.set('v', 'p', '"_dP', { expr = false })

-- Close buffer without closing the window
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete!<CR>', { desc = '[B]uffer [D]elete' })

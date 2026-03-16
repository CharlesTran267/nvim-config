return {
  'akinsho/toggleterm.nvim',
  branch = 'main',
  config = function()
    local toggleterm = require('toggleterm')
    local Terminal = require('toggleterm.terminal').Terminal

    toggleterm.setup({
      direction = 'float',
      highlights = {
        FloatBorder = {
          guifg = '#8aadf4', -- Catppuccin Macchiato blue
        },
      },
      winbar = {
        enabled = true,
        name_formatter = function(term)
          if term.display_name then
            return ' ' .. term.id .. ': ' .. term.display_name
          end
          return ' Terminal ' .. term.id
        end,
      },
    })

    -- Create predefined terminals
    local random_term = Terminal:new({
      display_name = 'random',
      direction = 'float',
      count = 1,
    })

    local lazygit_term = Terminal:new({
      cmd = 'lazygit',
      display_name = 'lazygit',
      direction = 'float',
      count = 2,
    })

    local aider_term = Terminal:new({
      cmd = 'aider',
      display_name = 'aider',
      direction = 'float',
      count = 3,
    })

    local codex_term = Terminal:new({
      cmd = 'codex',
      display_name = 'codex',
      direction = 'float',
      count = 4,
    })

    -- Keymaps for each terminal
    vim.keymap.set({ 'n', 't' }, '<A-i>', function() random_term:toggle() end, { desc = 'Toggle random terminal' })
    vim.keymap.set({ 'n', 't' }, '<A-g>', function() lazygit_term:toggle() end, { desc = 'Toggle lazygit' })
    vim.keymap.set({ 'n', 't' }, '<A-a>', function() aider_term:toggle() end, { desc = 'Toggle aider' })
    vim.keymap.set({ 'n', 't' }, '<A-c>', function() codex_term:toggle() end, { desc = 'Toggle codex' })

    -- Quick select terminal
    vim.keymap.set({ 'n', 't' }, '<A-s>', '<Cmd>TermSelect<CR>', { desc = 'Select terminal' })
    -- Create new terminal
    vim.keymap.set({ 'n', 't' }, '<A-n>', '<Cmd>TermNew direction=float<CR>', { desc = 'New terminal' })
  end,
}

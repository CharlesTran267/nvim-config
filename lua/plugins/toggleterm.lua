return {
  'akinsho/toggleterm.nvim',
  branch = 'main',
  config = function()
    require('toggleterm').setup {
      direction = 'float',
      open_mapping = [[<A-i>]],
      highlights = {
        FloatBorder = {
          guifg = '#8aadf4', -- Catppuccin Macchiato blue
        },
      },
      winbar = {
        enabled = true,
        -- name_formatter = function(term)
        --   return term.name
        -- end,
      },
    }

    -- Quick select terminal
    vim.keymap.set({ 'n', 't' }, '<A-s>', '<Cmd>TermSelect<CR>', { desc = 'Select terminal' })
    -- Create new terminal
    vim.keymap.set({ 'n', 't' }, '<A-n>', '<Cmd>TermNew direction=float<CR>', { desc = 'New terminal' })
  end,
}

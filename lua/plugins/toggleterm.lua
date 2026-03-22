return {
  'akinsho/toggleterm.nvim',
  branch = 'main',
  config = function()
    local toggleterm = require 'toggleterm'
    local Terminal = require('toggleterm.terminal').Terminal

    toggleterm.setup {
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
    }

    -- Predefined terminal configs (lazy - only created when first accessed)
    local terminal_configs = {
      lazygit = { cmd = 'lazygit', display_name = 'lazygit', direction = 'float' },
      aider = { cmd = 'aider', display_name = 'aider', direction = 'float' },
      codex = { cmd = 'codex', display_name = 'codex', direction = 'float' },
      aichat = { cmd = 'aichat', display_name = 'aichat', direction = 'float' },
    }

    local terminals = {}
    local last_terminal = nil

    local function get_terminal(name)
      if not terminals[name] then
        terminals[name] = Terminal:new(terminal_configs[name])
      end
      return terminals[name]
    end

    local function toggle_terminal(name)
      local term = get_terminal(name)
      last_terminal = name
      term:toggle()
    end

    -- Toggle last-used terminal (defaults to a general terminal)
    vim.keymap.set({ 'n', 't' }, '<A-i>', function()
      if last_terminal then
        toggle_terminal(last_terminal)
      else
        vim.cmd 'ToggleTerm direction=float'
      end
    end, { desc = 'Toggle last terminal' })

    -- Terminal picker
    vim.keymap.set({ 'n', 't' }, '<A-s>', function()
      local options = { 'lazygit', 'aider', 'codex', 'aichat', 'terminal', 'new terminal' }
      vim.ui.select(options, { prompt = 'Select terminal:' }, function(choice)
        if not choice then
          return
        end
        if choice == 'terminal' then
          vim.cmd 'ToggleTerm direction=float'
        else
          toggle_terminal(choice)
        end
      end)
    end, { desc = 'Select terminal' })

    -- Close current terminal
    vim.keymap.set('t', '<A-q>', '<Cmd>close<CR>', { desc = 'Close terminal' })

    -- Create new terminal
    vim.keymap.set({ 'n', 't' }, '<A-n>', '<Cmd>ToggleTerm direction=float<CR>', { desc = 'New terminal' })
  end,
}

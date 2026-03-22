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
      general = { cmd = vim.o.shell, display_name = 'general', direction = 'float' },
      lazygit = { cmd = 'lazygit', display_name = 'lazygit', direction = 'float' },
      aider = { cmd = 'aider', display_name = 'aider', direction = 'float' },
      codex = { cmd = 'codex', display_name = 'codex', direction = 'float' },
      aichat = { cmd = 'aichat', display_name = 'aichat', direction = 'float' },
    }

    local terminals = {}
    local custom_shells = {} -- Track user-created shells
    local last_terminal = 'general'

    local function get_terminal(name)
      if not terminals[name] then
        local config = terminal_configs[name] or { cmd = vim.o.shell, display_name = name, direction = 'float' }
        terminals[name] = Terminal:new(config)
      end
      return terminals[name]
    end

    local function toggle_terminal(name)
      local term = get_terminal(name)
      last_terminal = name
      term:toggle()
    end

    local function create_new_shell(name)
      terminal_configs[name] = { cmd = vim.o.shell, display_name = name, direction = 'float' }
      table.insert(custom_shells, name)
      toggle_terminal(name)
    end

    -- Toggle last-used terminal (defaults to general)
    vim.keymap.set({ 'n', 't' }, '<A-i>', function()
      toggle_terminal(last_terminal)
    end, { desc = 'Toggle last terminal' })

    -- Terminal picker
    vim.keymap.set({ 'n', 't' }, '<A-s>', function()
      local options = { 'general', 'lazygit', 'aider', 'codex', 'aichat' }
      -- Add custom shells to the list
      for _, name in ipairs(custom_shells) do
        table.insert(options, name)
      end
      table.insert(options, '+ new shell')

      vim.ui.select(options, { prompt = 'Select terminal:' }, function(choice)
        if not choice then
          return
        end
        if choice == '+ new shell' then
          vim.ui.input({ prompt = 'Shell name: ' }, function(name)
            if name and name ~= '' then
              create_new_shell(name)
            end
          end)
        else
          toggle_terminal(choice)
        end
      end)
    end, { desc = 'Select terminal' })

    -- Quit current terminal (custom shells removed from list, predefined start fresh)
    vim.keymap.set('t', '<A-q>', function()
      local current_term = terminals[last_terminal]
      if current_term then
        current_term:shutdown()
        terminals[last_terminal] = nil -- Remove from cache so it starts fresh next time

        -- If it's a custom shell, remove it from the list entirely
        for i, name in ipairs(custom_shells) do
          if name == last_terminal then
            table.remove(custom_shells, i)
            terminal_configs[last_terminal] = nil
            break
          end
        end

        last_terminal = 'general'
      end
    end, { desc = 'Quit terminal' })

    -- Create new shell (prompts for name)
    vim.keymap.set({ 'n', 't' }, '<A-n>', function()
      vim.ui.input({ prompt = 'Shell name: ' }, function(name)
        if name and name ~= '' then
          create_new_shell(name)
        end
      end)
    end, { desc = 'New shell' })
  end,
}

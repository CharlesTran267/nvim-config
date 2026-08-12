return {
  'akinsho/toggleterm.nvim',
  branch = 'main',
  config = function()
    local toggleterm = require 'toggleterm'
    local Terminal = require('toggleterm.terminal').Terminal

    -- With TMUX cleared (see setup env below), claude stops clamping itself to
    -- 256 colors and its 24-bit output shifts hues through tmux. FORCE_COLOR=2
    -- restores the clamp. Per-terminal env REPLACES setup env, so repeat it.
    local claude_env = { TMUX = '', TMUX_PANE = '', TERM_PROGRAM = '', FORCE_COLOR = '2' }

    -- Predefined terminal configs (lazy - only created when first accessed)
    local terminal_configs = {
      general = { cmd = vim.o.shell, direction = 'float' },
      lazygit = { cmd = 'lazygit', direction = 'float' },
      aider = { cmd = 'aider', direction = 'float' },
      codex = { cmd = 'codex', direction = 'float' },
      ['claude-random'] = { cmd = 'claude', direction = 'float', env = claude_env },
      claude = { cmd = 'claude', direction = 'float', env = claude_env },
    }

    local terminals = {}
    local custom_shells = {} -- Track user-created shells
    local last_terminal = 'general'
    local terminal_history = { 'general' } -- Track visited terminals in order
    local history_index = 1

    -- Build the winbar string for a terminal (called dynamically each redraw).
    -- Toggleterm skips its built-in winbar for floats, so we set it manually.
    _G.__toggleterm_custom_winbar = function(current_id)
      local parts = {}
      for _, name in ipairs(terminal_history) do
        local t = terminals[name]
        if t then
          if t.id == current_id then
            table.insert(parts, '%#ToggletermWinbarSel# ▶ ' .. name .. ' %*')
          else
            table.insert(parts, '%#ToggletermWinbar#   ' .. name .. ' %*')
          end
        end
      end
      if #parts == 0 then return ' ' end
      return '%#ToggletermWinbar# ' .. table.concat(parts, '') .. '%#ToggletermWinbar#%='
    end

    -- Give the winbar a distinct background so it doesn't blend into terminal content
    local ok, palette = pcall(require, 'catppuccin.palettes')
    local c = ok and palette.get_palette() or {}
    vim.api.nvim_set_hl(0, 'ToggletermWinbar', { bg = c.mantle or '#1e2030', fg = c.subtext0 or '#a5adcb', bold = true })
    vim.api.nvim_set_hl(0, 'ToggletermWinbarSel', { bg = c.surface0 or '#363a4f', fg = c.red or '#ed8796', bold = true })

    toggleterm.setup {
      direction = 'float',
      start_in_insert = true,
      -- nvim's :terminal is the real parent, not tmux. With TMUX set, TUIs wrap
      -- OSC 52 clipboard writes in tmux passthrough, which nvim paints as text.
      env = { TMUX = '', TMUX_PANE = '', TERM_PROGRAM = '' },
      winbar = { enabled = false }, -- disable built-in winbar; we set our own in on_open
      highlights = {
        FloatBorder = {
          guifg = '#8aadf4', -- Catppuccin Macchiato blue
        },
      },
      on_open = function(term)
        if term.window and vim.api.nvim_win_is_valid(term.window) then
          vim.wo[term.window].winbar = string.format('%%{%%v:lua.__toggleterm_custom_winbar(%d)%%}', term.id)
        end
      end,
    }

    -- Mouse drag only reaches the child while nvim is in Terminal mode, so landing in
    -- terminal-normal breaks claude's drag-select as well as feeling wrong. An autocmd has
    -- no race window; vim.schedule(startinsert) in on_open lost to fast toggles/keypresses.
    vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
      pattern = 'term://*',
      callback = function() vim.cmd 'startinsert' end,
    })

    local function get_terminal(name)
      if not terminals[name] then
        local config = terminal_configs[name] or { cmd = vim.o.shell, display_name = name, direction = 'float' }
        terminals[name] = Terminal:new(config)
      end
      return terminals[name]
    end

    local function toggle_terminal(name)
      local term = get_terminal(name)
      -- Update history
      if name ~= last_terminal then
        -- Remove if already in history, then add to end
        for i, n in ipairs(terminal_history) do
          if n == name then
            table.remove(terminal_history, i)
            break
          end
        end
        table.insert(terminal_history, name)
        history_index = #terminal_history
      end
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
      local options = { 'general', 'lazygit', 'aider', 'codex', 'claude-random', 'claude' }
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

        -- Remove from history
        for i, n in ipairs(terminal_history) do
          if n == last_terminal then
            table.remove(terminal_history, i)
            if history_index > #terminal_history then
              history_index = math.max(1, #terminal_history)
            end
            break
          end
        end

        -- If it's a custom shell, remove it from the list entirely
        for i, name in ipairs(custom_shells) do
          if name == last_terminal then
            table.remove(custom_shells, i)
            terminal_configs[last_terminal] = nil
            break
          end
        end

        last_terminal = terminal_history[history_index] or 'general'
      end
    end, { desc = 'Quit terminal' })

    -- Toggle general terminal
    vim.keymap.set({ 'n', 't' }, '<A-g>', function()
      toggle_terminal('general')
    end, { desc = 'Toggle general terminal' })

    -- Navigate to previous terminal in history (wraps around)
    vim.keymap.set({ 'n', 't' }, '<A-p>', function()
      if #terminal_history < 2 then return end
      history_index = (history_index - 2) % #terminal_history + 1
      local name = terminal_history[history_index]
      local term = get_terminal(name)
      if terminals[last_terminal] then
        terminals[last_terminal]:close()
      end
      last_terminal = name
      term:open()
    end, { desc = 'Previous terminal (history)' })

    -- Navigate to next terminal in history (wraps around)
    vim.keymap.set({ 'n', 't' }, '<A-n>', function()
      if #terminal_history < 2 then return end
      history_index = history_index % #terminal_history + 1
      local name = terminal_history[history_index]
      local term = get_terminal(name)
      if terminals[last_terminal] then
        terminals[last_terminal]:close()
      end
      last_terminal = name
      term:open()
    end, { desc = 'Next terminal (history)' })

    -- Create new shell (prompts for name)
    vim.keymap.set({ 'n', 't' }, '<A-S-n>', function()
      vim.ui.input({ prompt = 'Shell name: ' }, function(name)
        if name and name ~= '' then
          create_new_shell(name)
        end
      end)
    end, { desc = 'New shell' })
  end,
}

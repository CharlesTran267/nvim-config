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

    -- No display_name: toggleterm would draw it as the float's border title, and the
    -- winbar already names every terminal.
    local function shell()
      return { cmd = vim.o.shell }
    end

    -- Picker order. Any other name is a user shell created on demand.
    local predefined = { 'general', 'random', 'lazygit', 'codex', 'claude', 'claude2', 'claude3' }
    local configs = {
      general = shell(),
      random = { cmd = vim.o.shell, dir = vim.fn.expand '~/random' },
      lazygit = { cmd = 'lazygit' },
      -- Codex draws inline (alt screen only for its Ctrl-T/diff overlays), so its
      -- transcript is nvim scrollback: wheel-up reads it in terminal-normal mode.
      codex = { cmd = 'codex' },
      claude = { cmd = 'claude', env = claude_env },
      claude2 = { cmd = 'claude', env = claude_env },
      claude3 = { cmd = 'claude', env = claude_env },
    }

    local terminals = {} -- name -> Terminal, created on first use
    local history = { 'general' } -- visit order, most recent last
    local history_index = 1
    local function current()
      return history[history_index] or 'general'
    end

    local function get_terminal(name)
      if not terminals[name] then
        -- Terminal:new mutates and returns the table it is given; hand it a copy so a
        -- terminal restarted after <A-q> does not inherit stale bufnr/window fields.
        terminals[name] = Terminal:new(vim.deepcopy(configs[name] or shell()))
      end
      return terminals[name]
    end

    -- Give the winbar a distinct background so it doesn't blend into terminal content.
    -- Colors come from gruvbox-material (accent = i3 focused-border yellow). With any other
    -- colorscheme the palette call fails and the Catppuccin Macchiato fallbacks apply.
    local ok, c = pcall(function()
      local conf = vim.fn['gruvbox_material#get_configuration']()
      local p = vim.fn['gruvbox_material#get_palette'](conf.background, conf.foreground, conf.colors_override)
      return { bg = p.bg1[1], fg = p.grey2[1], sel_bg = p.yellow[1], sel_fg = p.bg0[1], accent = p.yellow[1] }
    end)
    c = ok and c or {}
    vim.api.nvim_set_hl(0, 'ToggletermWinbar', { bg = c.bg or '#1e2030', fg = c.fg or '#a5adcb', bold = true })
    vim.api.nvim_set_hl(0, 'ToggletermWinbarSel', { bg = c.sel_bg or '#363a4f', fg = c.sel_fg or '#ed8796', bold = true })

    toggleterm.setup {
      direction = 'float',
      -- Always reopen terminals ready for input instead of restoring an
      -- accidentally persisted terminal-normal state.
      persist_mode = false,
      -- Default true runs `normal! G` on every output chunk while in terminal-normal,
      -- yanking a scrolled-up view back down (unreadable while Codex streams).
      -- Terminal mode still follows output on its own.
      auto_scroll = false,
      -- nvim's :terminal is the real parent, not tmux. With TMUX set, TUIs wrap
      -- OSC 52 clipboard writes in tmux passthrough, which nvim paints as text.
      env = { TMUX = '', TMUX_PANE = '', TERM_PROGRAM = '' },
      highlights = { FloatBorder = { guifg = c.accent or '#8aadf4' } }, -- fallback: Catppuccin Macchiato blue
      -- Toggleterm skips its built-in winbar for floats; list the visited terminals
      -- ourselves. History only changes through actions that reopen a window, so a
      -- plain string set on open stays current.
      on_open = function(term)
        local parts = {}
        for _, name in ipairs(history) do
          local hl = terminals[name] == term and '%#ToggletermWinbarSel# ▶ ' or '%#ToggletermWinbar#   '
          parts[#parts + 1] = hl .. name .. ' '
        end
        vim.wo[term.window].winbar = '%#ToggletermWinbar# ' .. table.concat(parts) .. '%#ToggletermWinbar#%='
      end,
    }

    -- In terminal mode the view is already at the bottom. A child with mouse reporting
    -- (claude, lazygit, anything run inside a shell) gets the wheel-down; for one
    -- without, nvim drops to terminal-normal instead, so undo that.
    vim.keymap.set('t', '<ScrollWheelDown>', function()
      vim.schedule(function()
        if vim.api.nvim_get_mode().mode == 'nt' then
          vim.cmd 'startinsert'
        end
      end)
      return '<ScrollWheelDown>'
    end, { expr = true, desc = 'Wheel-down without leaving terminal mode' })

    -- Wheel-down that reaches the bottom re-enters terminal mode, so read-then-return
    -- needs no `i`. Pointer over another window: hand the event back for the default scroll.
    vim.api.nvim_create_autocmd('TermOpen', {
      callback = function(ev)
        vim.keymap.set('n', '<ScrollWheelDown>', function()
          if vim.fn.getmousepos().winid ~= vim.api.nvim_get_current_win() then
            return vim.api.nvim_feedkeys(vim.keycode '<ScrollWheelDown>', 'n', false)
          end
          local lines = vim.o.mousescroll:match 'ver:(%d+)' or 3
          vim.cmd(('normal! %d%s'):format(lines, vim.keycode '<C-e>'))
          if vim.fn.line 'w$' >= vim.fn.line '$' then
            vim.cmd 'startinsert'
          end
        end, { buffer = ev.buf, desc = 'Scroll down; re-enter terminal mode at bottom' })
      end,
    })

    -- toggleterm enters Terminal mode from a scheduled BufEnter callback, and nvim runs
    -- pending keys before scheduled callbacks: keys typed right after a toggle ran as
    -- Normal commands. :startinsert here takes effect before the next key is read.
    local function enter_terminal_mode()
      if vim.bo.buftype == 'terminal' then
        vim.cmd 'startinsert'
      end
    end

    local function toggle_terminal(name)
      if history[history_index] ~= name then -- move to the end of history (most recent)
        for i, n in ipairs(history) do
          if n == name then
            table.remove(history, i)
            break
          end
        end
        table.insert(history, name)
        history_index = #history
      end
      get_terminal(name):toggle()
      enter_terminal_mode()
    end

    local function new_shell()
      vim.ui.input({ prompt = 'Shell name: ' }, function(name)
        if name and name ~= '' then
          toggle_terminal(name)
        else
          vim.schedule(enter_terminal_mode) -- cancelled: back to the terminal we came from
        end
      end)
    end

    -- Step through history with wrap-around, closing the current float first.
    local function cycle(step)
      if #history < 2 then
        return
      end
      local cur = terminals[history[history_index]]
      history_index = (history_index - 1 + step) % #history + 1
      if cur then
        cur:close()
      end
      get_terminal(history[history_index]):open()
      enter_terminal_mode()
    end

    -- Terminal-mode chords leave Terminal mode through typeahead and replay as the n map,
    -- so keys typed right after them stay queued behind the switch. (Running the action
    -- inside the terminal loop let toggleterm's WinLeave `stopinsert!` cancel the new
    -- terminal's startinsert; vim.schedule let typed keys overtake it.)
    -- The <C-\><C-n> also strands you in terminal-normal when the action is a no-op
    -- (one-entry history, nothing to quit), so re-enter afterwards if still on a terminal.
    local function map(lhs, fn, desc)
      vim.keymap.set('n', lhs, function()
        fn()
        enter_terminal_mode()
      end, { desc = desc })
      vim.keymap.set('t', lhs, '<C-\\><C-n>' .. lhs, { remap = true, desc = desc })
    end

    map('<A-i>', function()
      toggle_terminal(current())
    end, 'Toggle last terminal')
    map('<A-g>', function()
      toggle_terminal 'general'
    end, 'Toggle general terminal')
    map('<A-p>', function()
      cycle(-1)
    end, 'Previous terminal (history)')
    map('<A-n>', function()
      cycle(1)
    end, 'Next terminal (history)')
    map('<A-S-n>', new_shell, 'New shell')

    map('<A-s>', function()
      local options = vim.deepcopy(predefined)
      local custom = vim.tbl_filter(function(n)
        return not vim.list_contains(predefined, n)
      end, vim.tbl_keys(terminals))
      table.sort(custom)
      vim.list_extend(options, custom)
      table.insert(options, '+ new shell')
      vim.ui.select(options, { prompt = 'Select terminal:' }, function(choice)
        if choice == '+ new shell' then
          new_shell()
        elseif choice then
          toggle_terminal(choice)
        else
          vim.schedule(enter_terminal_mode) -- telescope restores focus after this callback
        end
      end)
    end, 'Select terminal')

    -- Quit current terminal: user shells leave the picker, predefined ones start fresh next time.
    map('<A-q>', function()
      if vim.bo.buftype ~= 'terminal' then -- unmapped <M-q> in a file would run as <Esc>q
        return
      end
      local name = current()
      if not terminals[name] then
        return
      end
      terminals[name]:shutdown()
      terminals[name] = nil
      table.remove(history, history_index)
      history_index = math.max(1, math.min(history_index, #history))
    end, 'Quit terminal')
  end,
}

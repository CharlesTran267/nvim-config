return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  config = function()
    local highlight = {
      'RainbowRed',
      'RainbowYellow',
      'RainbowBlue',
      'RainbowOrange',
      'RainbowGreen',
      'RainbowViolet',
      'RainbowCyan',
    }

    local hooks = require 'ibl.hooks'
    -- create the highlight groups in the highlight setup hook, so they are reset
    -- every time the colorscheme changes
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      -- Colors come from gruvbox-material (same lookup as toggleterm.lua). With any other
      -- colorscheme the palette call fails and the original One Dark colors apply.
      local ok, p = pcall(function()
        local conf = vim.fn['gruvbox_material#get_configuration']()
        return vim.fn['gruvbox_material#get_palette'](conf.background, conf.foreground, conf.colors_override)
      end)
      local function color(name, fallback) return ok and p[name][1] or fallback end
      vim.api.nvim_set_hl(0, 'RainbowRed', { fg = color('red', '#E06C75') })
      vim.api.nvim_set_hl(0, 'RainbowYellow', { fg = color('yellow', '#E5C07B') })
      vim.api.nvim_set_hl(0, 'RainbowBlue', { fg = color('blue', '#61AFEF') })
      vim.api.nvim_set_hl(0, 'RainbowOrange', { fg = color('orange', '#D19A66') })
      vim.api.nvim_set_hl(0, 'RainbowGreen', { fg = color('green', '#98C379') })
      vim.api.nvim_set_hl(0, 'RainbowViolet', { fg = color('purple', '#C678DD') })
      vim.api.nvim_set_hl(0, 'RainbowCyan', { fg = color('aqua', '#56B6C2') })
    end)

    require('ibl').setup { indent = { highlight = highlight } }
  end,
}

return {
  {
    'catppuccin/nvim',
    lazy = false,
    name = 'catppuccin',
    priority = 1000,
    config = function()
      local transparent = true

      require('catppuccin').setup {
        flavour = transparent and 'macchiato',
        transparent_background = transparent,
        styles = {
          keywords = { 'bold' },
          functions = { 'italic' },
        },
        integrations = {
          alpha = false,
          neogit = false,
          nvimtree = true,
          illuminate = false,
          treesitter_context = false,
          rainbow_delimiters = false,
          dropbar = { enabled = false },
          mason = true,
          noice = true,
          notify = true,
          neotest = true,
          which_key = true,
          telescope = { style = transparent and nil or 'nvchad' },
        },
        custom_highlights = function(colors)
          return {
            -- custom
            PanelHeading = {
              fg = colors.lavender,
              bg = transparent and colors.none or colors.crust,
              style = { 'bold', 'italic' },
            },

            -- treesitter-context
            TreesitterContextLineNumber = {
              fg = colors.rosewater,
            },

            -- lazy.nvim
            LazyH1 = {
              bg = transparent and colors.none or colors.peach,
              fg = transparent and colors.lavender or colors.base,
              style = { 'bold' },
            },
            LazyButton = {
              bg = colors.none,
              fg = transparent and colors.overlay0 or colors.subtext0,
            },
            LazyButtonActive = {
              bg = transparent and colors.none or colors.overlay1,
              fg = transparent and colors.lavender or colors.base,
              style = { 'bold' },
            },
            LazySpecial = { fg = colors.green },

            CmpItemMenu = { fg = colors.subtext1 },
            MiniIndentscopeSymbol = { fg = colors.overlay0 },

            FloatBorder = {
              fg = transparent and colors.blue or colors.mantle,
              bg = transparent and colors.none or colors.mantle,
            },

            FloatTitle = {
              fg = transparent and colors.lavender or colors.base,
              bg = transparent and colors.none or colors.lavender,
            },
          }
        end,
        color_overrides = {
          mocha = {
            red = '#f07c82',
            blue = '#70a1ff',
            green = '#7bed9f',
            yellow = '#ffeaa7',

            sky = '#5ef1ff',
            pink = '#ffacfc',
            peach = '#ffbe76',
          },
        },
      }
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}

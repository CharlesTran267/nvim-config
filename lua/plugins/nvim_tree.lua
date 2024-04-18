return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('nvim-tree').setup {
      git = {
        enable = true,
        ignore = false,
        timeout = 500,
      },
    }
    -- Open nvim tree
    vim.keymap.set('n', '<C-B>', ':NvimTreeToggle<CR>')
  end,
}

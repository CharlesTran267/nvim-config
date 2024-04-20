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
      view = { side = 'left', width = 25 },
      update_focused_file = { enable = true, update_cwd = false },
      renderer = {
        highlight_modified = 'all',
        highlight_git = true,
        root_folder_label = false,
        indent_markers = { enable = true },
      },
    }
    -- Toggle nvim tree
    vim.keymap.set('n', '<C-B>', ':NvimTreeToggle<CR>')
  end,
}

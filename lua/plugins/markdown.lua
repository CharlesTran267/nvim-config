return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  config = function(_, opts)
    require('render-markdown').setup {
      completions = { lsp = { enabled = true } },
      enabled = false, -- disabled by default, toggle with <leader>mt
    }

    -- Leader + m + t to toggle markdown preview
    vim.keymap.set('n', '<leader>mt', function()
      require('render-markdown').toggle()
    end, { desc = 'Toggle markdown preview' })
  end,
}

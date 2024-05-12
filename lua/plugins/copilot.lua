return {
  {
    'github/copilot.vim',
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'canary',
    dependencies = {
      { 'zbirenbaum/copilot.lua' }, -- or github/copilot.vim
      { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
    },
    opts = {
      mappings = {
        reset = {
          normal = '<S-l>',
          insert = '<S-l>',
        },
      },
    },
    config = function()
      require('CopilotChat').setup {
        debug = true,
      }

      vim.keymap.set('n', '<leader>cc', ':CopilotChatToggle<CR>')
    end,
  },
}

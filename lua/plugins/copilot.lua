return {
  {
    'github/copilot.vim',
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'github/copilot.vim' },
      { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
    },
    config = function()
      require('CopilotChat').setup {
        debug = true,
        mappings = {
          reset = {
            normal = '<A-l>',
            insert = '<A-l>',
          },
          complete = {
            insert = '<S-Tab>',
          }
        },
      }

      vim.keymap.set('n', '<leader>cc', ':CopilotChatToggle<CR>')
    end,
  },
}

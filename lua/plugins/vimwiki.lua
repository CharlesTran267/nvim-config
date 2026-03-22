return {
  'vimwiki/vimwiki',
  event = 'BufEnter *.wiki',
  keys = {
    { '<leader>ww', '<cmd>VimwikiIndex<cr>', desc = 'Open Vimwiki Index' },
    { '<leader>wt', '<cmd>VimwikiTabIndex<cr>', desc = 'Open Vimwiki Index in new tab' },
    { '<leader>ws', '<cmd>VimwikiUISelect<cr>', desc = 'Select Vimwiki' },
    { '<leader>wi', '<cmd>VimwikiDiaryIndex<cr>', desc = 'Open Vimwiki Diary Index' },
    { '<leader>wn', '<cmd>VimwikiMakeDiaryNote<cr>', desc = 'Create new diary note' },
  },
  init = function()
    vim.g.vimwiki_list = {
      {
        path = '~/vimwiki/',
        syntax = 'markdown',
        ext = '.md',
      },
    }
    -- Prevent vimwiki from hijacking all markdown files
    vim.g.vimwiki_global_ext = 0
  end,
}

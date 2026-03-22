return {
  'vimwiki/vimwiki',
  event = 'BufEnter *.md',
  keys = {
    { '<leader>w<leader>d', function() require('config.vimwiki_diary').open_today() end, desc = 'Open today diary' },
    { '<leader>w<leader>w', function() require('config.vimwiki_diary').open_week() end, desc = 'Open this week' },
    { '<leader>w<leader>Y', function() require('config.vimwiki_diary').open_year() end, desc = 'Open this year' },
    { '<leader>ww', '<cmd>VimwikiIndex<cr>', desc = 'Open Vimwiki Index' },
    { '<leader>wt', '<cmd>VimwikiTabIndex<cr>', desc = 'Open Vimwiki Index in new tab' },
    { '<leader>ws', '<cmd>VimwikiUISelect<cr>', desc = 'Select Vimwiki' },
    { '<leader>wi', '<cmd>VimwikiDiaryIndex<cr>', desc = 'Open Vimwiki Diary Index' },
    { '<leader>wn', '<cmd>VimwikiMakeDiaryNote<cr>', desc = 'Create new diary note' },
  },
  init = function()
    vim.g.vimwiki_list = {
      {
        path = '/home/charlestran/vimwiki/',
        syntax = 'markdown',
        ext = '.md',
      },
    }
    -- Prevent vimwiki from hijacking all markdown files
    vim.g.vimwiki_global_ext = 0
    -- Disable key mappings that conflict with other plugins
    vim.g.vimwiki_key_mappings = {
      table_mappings = 0,  -- fixes Tab in insert mode
      table_format = 0,
    }
  end,
}

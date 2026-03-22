return {
  'vimwiki/vimwiki',
  event = 'BufEnter *.md',
  keys = {
    { '<leader>w<leader>d', function() require('config.vimwiki_diary').open_today() end, desc = 'Open today diary' },
    { '<leader>w<leader>y', function() require('config.vimwiki_diary').open_yesterday() end, desc = 'Open yesterday diary' },
    { '<leader>w<leader>t', function() require('config.vimwiki_diary').open_tomorrow() end, desc = 'Open tomorrow diary' },
    { '<leader>w<leader>w', function() require('config.vimwiki_diary').open_week() end, desc = 'Open this week' },
    { '<leader>w<leader>n', function() require('config.vimwiki_diary').open_next_week() end, desc = 'Open next week' },
    { '<leader>w<leader>p', function() require('config.vimwiki_diary').open_prev_week() end, desc = 'Open previous week' },
    { '<leader>w<leader>Y', function() require('config.vimwiki_diary').open_year() end, desc = 'Open this year' },
    { '<leader>w<leader>r', function() require('config.vimwiki_diary').refresh_week() end, desc = 'Refresh week index' },
    { '<leader>w<leader>R', function() require('config.vimwiki_diary').refresh_year() end, desc = 'Refresh year index' },
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

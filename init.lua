-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed
vim.g.have_nerd_font = true

-- Create an augroup for managing the working directory
vim.api.nvim_create_augroup('AutoCWD', { clear = true })
-- Automatically set the working directory.
-- If no argument is passed to Neovim, set the working directory to the current directory
vim.api.nvim_create_autocmd('VimEnter', {
  group = 'AutoCWD',
  callback = function()
    local arg = vim.fn.argv(0) -- Get the first argument passed to Neovim
    -- print the argument passed to Neovim
    if arg == '' then
      -- No argument, set to the current directory
      vim.cmd('cd ' .. vim.fn.getcwd())
    else
      -- Strip 'oil://' prefix if it exists
      local resolved_path = vim.fn.fnamemodify(arg, ':h'):gsub('^oil://', '')
      vim.cmd('cd ' .. resolved_path)
    end
  end,
})

-- Add options, autocmd, and keymaps
require 'options'
require 'autocmd'
require 'keymaps'
require 'health'
require 'env'

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins', {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et

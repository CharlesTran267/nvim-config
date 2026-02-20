-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '~/.config/kitty/kitty.conf',
  command = 'silent !kill -SIGUSR1 $(pgrep kitty)',
})

-- Create an augroup for managing the working directory
vim.api.nvim_create_augroup('AutoCWD', { clear = true })
-- Automatically set the working directory.
vim.api.nvim_create_autocmd('VimEnter', {
  group = 'AutoCWD',
  callback = function()
    local arg = vim.fn.argv(0) -- Get the first argument passed to Neovim
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

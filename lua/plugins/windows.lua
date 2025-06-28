return {
  'anuvyklack/windows.nvim',
  dependencies = {
    'anuvyklack/middleclass',
    'anuvyklack/animation.nvim',
  },
  config = function()
    vim.o.winwidth = 10
    vim.o.winminwidth = 10
    vim.o.equalalways = false
    require('windows').setup {
      ignore = {
        buftype = { 'nofile' },
        filetype = { 'Avante' },
      },
    }

    local function cmd(command)
      return table.concat { '<Cmd>', command, '<CR>' }
    end

    vim.keymap.set('n', '<C-w>z', cmd 'WindowsMaximize')
  end,
}

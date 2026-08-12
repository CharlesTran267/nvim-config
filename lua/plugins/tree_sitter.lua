return { -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false, -- main does not support lazy-loading
  build = ':TSUpdate',
  config = function()
    local ts = require 'nvim-treesitter'
    ts.setup {}
    ts.install {
      'bash',
      'c',
      'cpp',
      'html',
      'javascript',
      'json',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'python',
      'rust',
      'vim',
      'vimdoc',
      'xml',
      'yaml',
    }

    -- main ships no modules: highlight and indent are opt-in per buffer.
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
        if not vim.tbl_contains(ts.get_installed(), lang) then
          if not vim.tbl_contains(ts.get_available(), lang) then
            return
          end
          ts.install(lang):await(function()
            vim.schedule(function() pcall(vim.treesitter.start, ev.buf) end)
          end)
          return
        end
        if not pcall(vim.treesitter.start, ev.buf) then
          return
        end
        if ev.match == 'ruby' then
          vim.bo[ev.buf].syntax = 'on' -- ruby needs regex highlighting for indent rules
        else
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}

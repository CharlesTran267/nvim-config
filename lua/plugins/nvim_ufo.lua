return {
  'kevinhwang91/nvim-ufo',
  dependencies = {
    'kevinhwang91/promise-async',
  },
  config = function()
    vim.o.foldcolumn = '1' -- '0' is not bad
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
    vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
    vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
    vim.keymap.set('n', 'zK', function()
      local winid = require('ufo').peekFoldedLinesUnderCursor()
      if not winid then
        vim.lsp.buf.hover()
      end
    end, { desc = 'Peek Fold' })

    require('ufo').setup {
      open_fold_hl_timeout = 150,
      close_fold_kinds_for_ft = {
        -- default = { 'imports', 'comment' },
        -- json = { 'array' },
        -- c = { 'comment', 'region' },
        -- markdown = { 'comment' },
      },
      preview = {
        win_config = {
          winhighlight = 'Normal:Folded',
          winblend = 0,
        },
        mappings = {
          scrollU = '<C-u>',
          scrollD = '<C-d>',
          jumpTop = '[',
          jumpBot = ']',
        },
      },
      provider_selector = function(bufnr, filetype, buftype)
        -- codediff manages folds itself (foldmethod=expr); ufo re-applying its
        -- remembered folds instantly re-closes anything the user opens
        for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
          if vim.w[win].codediff_restore then
            return ''
          end
        end
        if vim.api.nvim_buf_get_name(bufnr):match '^codediff://' then
          return ''
        end
        if filetype == 'markdown' then
          return { 'treesitter', 'indent' }
        end
        return { 'lsp', 'indent' }
      end,
      fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate, ctx)
        local newVirtText = {}
        local suffix = (' 󰁂 %d '):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, 'MoreMsg' })
        return newVirtText
      end,
    }

    -- On open: fold free functions and class methods, keep classes open.
    -- Both cpp and python name these nodes `function_definition`; classes
    -- are separate nodes, so they never match and stay unfolded.
    local function close_function_folds(bufnr)
      local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
      if not ok or not parser then
        return
      end
      local okq, query = pcall(vim.treesitter.query.parse, parser:lang(), '(function_definition) @fn')
      if not okq then
        return
      end
      local tree = parser:parse()[1]
      for _, node in query:iter_captures(tree:root(), bufnr) do
        local lnum = node:start() + 1
        -- skip lines already hidden inside a closed outer fold
        if vim.fn.foldlevel(lnum) > 0 and vim.fn.foldclosed(lnum) == -1 then
          vim.cmd(lnum .. 'foldclose')
        end
      end
    end

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'c', 'cpp', 'python' },
      callback = function(ev)
        -- leave codediff diff buffers alone (see provider_selector)
        if vim.w.codediff_restore or vim.api.nvim_buf_get_name(ev.buf):match '^codediff://' then
          return
        end
        local winid = vim.api.nvim_get_current_win()
        -- ufo applies folds async; apply treesitter folds ourselves first
        -- (ufo FAQ pattern) so folds exist before we close them
        require('async')(function()
          local ufo = require('ufo')
          ufo.attach(ev.buf)
          local ok, ranges = pcall(function()
            return await(ufo.getFolds(ev.buf, 'treesitter'))
          end)
          if not ok or not ranges or not ufo.applyFolds(ev.buf, ranges) then
            return
          end
          if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == ev.buf then
            vim.api.nvim_win_call(winid, function()
              close_function_folds(ev.buf)
            end)
          end
        end)
      end,
    })
  end,
}

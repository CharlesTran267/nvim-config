return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  config = function(_, opts)
    require('render-markdown').setup {
      completions = { lsp = { enabled = true } },
      enabled = false, -- disabled by default, toggle with <leader>mt
    }

    -- Leader + m + t to toggle markdown preview
    vim.keymap.set('n', '<leader>mt', function()
      require('render-markdown').toggle()
    end, { desc = 'Toggle markdown preview' })

    -- Leader + m + m to render the mermaid block under cursor to SVG and open it (zoomable).
    -- Needs `mmdc` on PATH: npm install -g @mermaid-js/mermaid-cli
    vim.keymap.set('n', '<leader>mm', function()
      vim.treesitter.get_parser():parse() -- nvim 0.12 parses async; make sure the tree exists
      local node = vim.treesitter.get_node()
      while node and node:type() ~= 'fenced_code_block' do
        node = node:parent()
      end
      local lang, body
      for child in (node and node:iter_children() or function() end) do
        if child:type() == 'info_string' then
          lang = vim.treesitter.get_node_text(child, 0)
        elseif child:type() == 'code_fence_content' then
          body = vim.treesitter.get_node_text(child, 0)
        end
      end
      if not (lang and lang:match '^mermaid' and body) then
        return vim.notify('No mermaid block under cursor', vim.log.levels.WARN)
      end
      local src, out = vim.fn.tempname() .. '.mmd', vim.fn.tempname() .. '.svg'
      vim.fn.writefile(vim.split(body, '\n'), src)
      vim.system({ 'mmdc', '-i', src, '-o', out }, {}, function(r)
        vim.schedule(function()
          if r.code ~= 0 then
            return vim.notify(r.stderr, vim.log.levels.ERROR)
          end
          vim.ui.open(out)
        end)
      end)
    end, { desc = 'Open mermaid diagram' })
  end,
}

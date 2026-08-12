return {
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  {
    -- Autoformat
    'stevearc/conform.nvim',
    lazy = false,
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      -- format_on_save = function(bufnr)
      --   -- Disable "format_on_save lsp_fallback" for languages that don't
      --   -- have a well standardized coding style. You can add additional
      --   -- languages here or re-enable it for the disabled ones.
      --   local disable_filetypes = {}
      --   return {
      --     timeout_ms = 500,
      --     lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
      --   }
      -- end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        -- You can use a function here to determine the formatters dynamically
        python = function(bufnr)
          if require('conform').get_formatter_info('ruff_format', bufnr).available then
            return { 'ruff_format' }
          else
            return { 'black' }
          end
        end,
        --
        -- You can use a sub-list to tell conform to run *until* a formatter
        -- is found.
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        cpp = { 'clang-format' },
        c = { 'clang-format' },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        -- Use the "*" filetype to run formatters on all filetypes.
        ['*'] = { 'codespell' },
        -- Use the "_" filetype to run formatters on filetypes that don't
        -- have other formatters configured.
        ['_'] = { 'trim_whitespace' },
      },
      -- Per-formatter config
      formatters = {
        -- Make clang-format use Google style
        ['clang-format'] = {
          prepend_args = { '--style={BasedOnStyle: Google, SortIncludes: false}' },
        },
        ['stylua'] = {
          prepend_args = { "--search-parent-directories", "--stdin-filepath", "$FILENAME", "--indent-type", "Spaces", "--indent-width", "4", "-" },
        }
      },
    },
  },
}

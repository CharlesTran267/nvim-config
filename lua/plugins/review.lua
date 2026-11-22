-- Code review in a codediff tab, review.nvim comments on top.
--   <leader>rh  working tree vs HEAD: unstaged shown, staged + untracked toggleable
--   <leader>rb  branch vs its base (merge-base): commits + staged + unstaged (+ untracked)
--   <leader>rB  set the base ref for this worktree
--   <leader>ru / rs / rc  toggle untracked / staged (uncommitted) / unstaged
-- Inside the explorer panel codediff also has gu (unstaged) and gs (staged).

-- codediff lists untracked files inside "Changes" as ??; this flag filters them out
local hide_untracked = true

-- Base ref: $GIT_DIR/review-base (per worktree), else origin/HEAD, else origin/develop
local function base_file()
  return vim.trim(vim.fn.system 'git rev-parse --absolute-git-dir') .. '/review-base'
end

local function base_ref()
  local saved = vim.fn.filereadable(base_file()) == 1 and vim.trim(vim.fn.readfile(base_file())[1] or '') or ''
  if saved ~= '' then
    return saved
  end
  return vim.trim(vim.fn.system 'git symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/develop')
end

local function toggle(what)
  return function()
    local ex = require('codediff.ui.lifecycle').get_explorer(vim.api.nvim_get_current_tabpage())
    if not ex then
      return vim.notify('No review in this tab', vim.log.levels.WARN, { title = 'review.nvim' })
    end
    if what == 'untracked' then
      hide_untracked = not hide_untracked
      require('codediff.ui.explorer').refresh(ex)
    else -- staged / unstaged groups exist in <leader>rh mode only
      require('codediff.ui.explorer.actions').toggle_group(ex, what)
    end
  end
end

return {
  'georgeguimaraes/review.nvim',
  version = '*',
  dependencies = {
    {
      'esmuellert/codediff.nvim',
      version = 'v2.49.2', -- last tag before Path refactor; review.nvim v1.9.1 wants strings
      opts = {
        explorer = {
          auto_refresh = false, -- git watcher refolds compact view and moves the cursor mid-review; R refreshes
          visible_groups = { staged = false, unstaged = true, conflicts = true },
          -- deep_extend replaces the list, so the .git/.jj defaults are repeated
          file_filter = {
            ignore = {
              '.git/**',
              '.jj/**',
              '*.diff',
              '*.patch',
              '*.orig',
              '*.rej',
              '*.zip',
              '*.pyc',
              '*.db-shm',
              '*.db-wal',
              '__pycache__/**',
              'agent-plans/**',
              'build/**',
              'install/**',
              'devel/**',
            },
          },
        },
      },
      config = function(_, opts)
        require('codediff').setup(opts)
        local tree = require 'codediff.ui.explorer.tree'
        local build = tree.create_tree_data
        tree.create_tree_data = function(status, ...)
          if hide_untracked then
            status = vim.tbl_extend('force', status, {
              unstaged = vim.tbl_filter(function(f)
                return f.status ~= '??'
              end, status.unstaged or {}),
            })
          end
          return build(status, ...)
        end
      end,
    },
    'MunifTanjim/nui.nvim',
  },
  init = function()
    -- codediff sets nowrap/scrollbind on its windows and never resets them;
    -- they leak into splits, :tabnew, and buffers it displayed (:h local-options)
    vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinNew' }, {
      group = vim.api.nvim_create_augroup('review_reset_winopts', {}),
      callback = function()
        local lifecycle = package.loaded['codediff.ui.lifecycle']
        if lifecycle and lifecycle.get_session(vim.api.nvim_get_current_tabpage()) then
          return
        end
        if vim.wo.diff then -- gitsigns diffthis needs scrollbind
          return
        end
        vim.wo.wrap = true
        vim.wo.scrollbind = false
        vim.wo.cursorbind = false
      end,
    })
  end,
  cmd = 'Review',
  keys = {
    { '<leader>rh', '<cmd>Review<cr>', desc = '[R]eview working tree vs [H]EAD' },
    {
      '<leader>rb',
      function()
        local ref = base_ref()
        local base = vim.trim(vim.fn.system('git merge-base HEAD ' .. vim.fn.shellescape(ref)))
        if vim.v.shell_error ~= 0 or base == '' then
          return vim.notify('No merge base with ' .. ref, vim.log.levels.ERROR, { title = 'review.nvim' })
        end
        -- One revision = base vs working tree. `Review commits` needs two, so do
        -- what review.open() does and let review.nvim attach via CodeDiffOpen.
        require('review.storage').clear_revisions()
        require('review.store').reset()
        require('review.store').load()
        vim.cmd('CodeDiff ' .. base)
      end,
      desc = '[R]eview branch vs [B]ase',
    },
    {
      '<leader>rB',
      function()
        vim.ui.input({ prompt = 'Review base ref: ', default = base_ref() }, function(ref)
          if ref and vim.trim(ref) ~= '' then
            vim.fn.writefile({ vim.trim(ref) }, base_file())
          end
        end)
      end,
      desc = '[R]eview set [B]ase ref (this worktree)',
    },
    { '<leader>ru', toggle 'untracked', desc = '[R]eview toggle [U]ntracked' },
    { '<leader>rs', toggle 'staged', desc = '[R]eview toggle [S]taged (uncommitted)' },
    { '<leader>rc', toggle 'unstaged', desc = '[R]eview toggle unstaged [C]hanges' },
  },
  -- edit mode: readonly mode leaves the real buffer [RO] after the tab closes
  opts = { codediff = { readonly = false } },
}

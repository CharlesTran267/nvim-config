-- Base ref lives in $GIT_DIR/review-base so each worktree keeps its own
-- (git config is shared across worktrees; a single value would be wrong in 6 of 7)
local function base_file()
  return vim.trim(vim.fn.system 'git rev-parse --absolute-git-dir') .. '/review-base'
end

local function base_ref()
  local f = base_file()
  if vim.fn.filereadable(f) == 1 then
    local saved = vim.trim(vim.fn.readfile(f)[1] or '')
    if saved ~= '' then
      return saved
    end
  end
  return vim.trim(vim.fn.system 'git symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/develop')
end

return {
  'georgeguimaraes/review.nvim',
  version = '*',
  dependencies = {
    {
      'esmuellert/codediff.nvim',
      version = 'v2.49.2', -- last tag before Path refactor; review.nvim v1.9.1 wants strings
      -- git watcher refresh re-folds compact view and yanks the cursor back
      -- into the diff window mid-review; refresh manually with R instead
      opts = { explorer = { auto_refresh = false } },
    },
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Review',
  keys = {
    {
      '<leader>rb',
      function()
        -- merge-base walks forward past every merge from the base branch, so
        -- the diff holds this branch's own commits only
        local ref = base_ref()
        local base = vim.trim(vim.fn.system('git merge-base HEAD ' .. vim.fn.shellescape(ref)))
        if vim.v.shell_error ~= 0 or base == '' then
          vim.notify('No merge base with ' .. ref, vim.log.levels.ERROR, { title = 'review.nvim' })
          return
        end
        vim.cmd('Review commits ' .. base .. ' HEAD')
      end,
      desc = '[R]eview vs [B]ase',
    },
    {
      '<leader>rB',
      function()
        vim.ui.input({ prompt = 'Review base ref: ', default = base_ref() }, function(ref)
          if ref and vim.trim(ref) ~= '' then
            vim.fn.writefile({ vim.trim(ref) }, base_file())
            vim.notify('Review base: ' .. vim.trim(ref), vim.log.levels.INFO, { title = 'review.nvim' })
          end
        end)
      end,
      desc = '[R]eview set [B]ase ref (this worktree)',
    },
    { '<leader>rh', '<cmd>Review<cr>', desc = '[R]eview vs [H]EAD (working tree)' },
  },
  opts = {},
}

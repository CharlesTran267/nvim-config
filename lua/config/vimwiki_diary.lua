local M = {}

local base_path = '/home/charlestran/vimwiki/diary'

local function ensure_dir(path)
  vim.fn.mkdir(path, 'p')
end

local function get_week_number(date)
  return os.date('%W', date)
end

local function scan_files(dir, pattern)
  local files = {}
  local handle = vim.loop.fs_scandir(dir)
  if handle then
    while true do
      local name = vim.loop.fs_scandir_next(handle)
      if not name then break end
      if name:match(pattern) then
        table.insert(files, name)
      end
    end
  end
  table.sort(files)
  return files
end

function M.open_today()
  local year = os.date('%Y')
  local week = get_week_number(os.time())
  local day = os.date('%Y-%m-%d')
  local dir = string.format('%s/%s/week%s', base_path, year, week)
  local filepath = dir .. '/' .. day .. '.md'
  
  ensure_dir(dir)
  vim.cmd('edit ' .. filepath)
  
  if vim.fn.filereadable(filepath) == 0 or vim.fn.getfsize(filepath) <= 0 then
    local lines = {
      '# ' .. day,
      '',
      '## Notes',
      '',
      '',
      '',
      '## TODO',
      '',
      '- [ ] ',
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd('write')
  end
end

function M.open_week()
  local year = os.date('%Y')
  local week = get_week_number(os.time())
  local dir = string.format('%s/%s/week%s', base_path, year, week)
  ensure_dir(dir)
  
  -- Calculate week start (Monday) and end (Sunday) dates
  local today = os.time()
  local wday = os.date('*t', today).wday
  local days_since_monday = (wday + 5) % 7  -- Monday = 0, Sunday = 6
  local monday = today - (days_since_monday * 86400)
  local sunday = monday + (6 * 86400)
  local start_date = os.date('%Y-%m-%d', monday)
  local end_date = os.date('%Y-%m-%d', sunday)
  
  local filepath = dir .. '/index.md'
  local days = scan_files(dir, '^%d%d%d%d%-%d%d%-%d%d%.md$')
  
  local lines = {
    '# Week ' .. week .. ': ' .. start_date .. '-' .. end_date,
    '',
    '## Days',
    '',
  }
  
  if #days > 0 then
    for _, day in ipairs(days) do
      table.insert(lines, '- [' .. day:gsub('%.md$', '') .. '](' .. day .. ')')
    end
  else
    table.insert(lines, '_No entries yet_')
  end
  
  table.insert(lines, '')
  table.insert(lines, '## Notes')
  table.insert(lines, '')
  table.insert(lines, '')
  table.insert(lines, '')
  table.insert(lines, '## TODO')
  table.insert(lines, '')
  table.insert(lines, '- [ ] ')
  
  vim.cmd('edit ' .. filepath)
  if vim.fn.filereadable(filepath) == 0 then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd('write')
  end
end

function M.open_year()
  local year = os.date('%Y')
  local dir = string.format('%s/%s', base_path, year)
  ensure_dir(dir)
  
  local filepath = dir .. '/index.md'
  local weeks = scan_files(dir, '^week%d+$')
  
  local lines = {
    '# ' .. year,
    '',
    '## Weeks',
    '',
  }
  
  if #weeks > 0 then
    for _, week in ipairs(weeks) do
      table.insert(lines, '- [' .. week .. '](' .. week .. '/index.md)')
    end
  else
    table.insert(lines, '_No entries yet_')
  end
  
  table.insert(lines, '')
  table.insert(lines, '## Notes')
  table.insert(lines, '')
  table.insert(lines, '')
  table.insert(lines, '')
  table.insert(lines, '## TODO')
  table.insert(lines, '')
  table.insert(lines, '- [ ] ')
  
  vim.cmd('edit ' .. filepath)
  if vim.fn.filereadable(filepath) == 0 then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd('write')
  end
end

return M

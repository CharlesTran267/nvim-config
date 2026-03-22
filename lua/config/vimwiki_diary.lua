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

local function read_file_lines(filepath)
  local lines = {}
  local file = io.open(filepath, 'r')
  if file then
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()
  end
  return lines
end

local function find_section_range(lines, section_name)
  local start_idx = nil
  local end_idx = nil
  
  for i, line in ipairs(lines) do
    if line:match('^## ' .. section_name) then
      start_idx = i
    elseif start_idx and line:match('^## ') then
      end_idx = i - 1
      break
    end
  end
  
  if start_idx and not end_idx then
    end_idx = #lines
  end
  
  return start_idx, end_idx
end

local function open_day(offset)
  local target = os.time() + (offset * 86400)
  local year = os.date('%Y', target)
  local week = get_week_number(target)
  local day = os.date('%Y-%m-%d', target)
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

function M.open_today()
  open_day(0)
end

function M.open_yesterday()
  open_day(-1)
end

function M.open_tomorrow()
  open_day(1)
end

local function open_week_offset(offset)
  local target = os.time() + (offset * 7 * 86400)
  local year = os.date('%Y', target)
  local week = get_week_number(target)
  local dir = string.format('%s/%s/week%s', base_path, year, week)
  ensure_dir(dir)
  
  -- Calculate week start (Monday) and end (Sunday) dates
  local wday = os.date('*t', target).wday
  local days_since_monday = (wday + 5) % 7
  local monday = target - (days_since_monday * 86400)
  local sunday = monday + (6 * 86400)
  local start_date = os.date('%Y-%m-%d', monday)
  local end_date = os.date('%Y-%m-%d', sunday)
  
  local filepath = dir .. '/index.md'
  local days = scan_files(dir, '^%d%d%d%d%-%d%d%-%d%d%.md$')
  local today = os.date('%Y-%m-%d')
  
  local existing_lines = read_file_lines(filepath)
  
  -- Build new Days section content
  local days_content = {}
  table.insert(days_content, '## Days')
  table.insert(days_content, '')
  if #days > 0 then
    for _, day in ipairs(days) do
      local day_name = day:gsub('%.md$', '')
      if day_name == today then
        table.insert(days_content, '- **[' .. day_name .. '](' .. day .. ') ← TODAY**')
      else
        table.insert(days_content, '- [' .. day_name .. '](' .. day .. ')')
      end
    end
  else
    table.insert(days_content, '_No entries yet_')
  end
  table.insert(days_content, '')
  
  local lines
  if #existing_lines > 0 then
    local start_idx, end_idx = find_section_range(existing_lines, 'Days')
    if start_idx then
      -- Replace existing Days section
      lines = {}
      for i = 1, start_idx - 1 do
        table.insert(lines, existing_lines[i])
      end
      for _, line in ipairs(days_content) do
        table.insert(lines, line)
      end
      for i = end_idx + 1, #existing_lines do
        table.insert(lines, existing_lines[i])
      end
    else
      -- No Days section, insert after header
      lines = { existing_lines[1], '' }
      for _, line in ipairs(days_content) do
        table.insert(lines, line)
      end
      for i = 2, #existing_lines do
        table.insert(lines, existing_lines[i])
      end
    end
  else
    -- New file
    lines = {
      '# Week ' .. week .. ': ' .. start_date .. '-' .. end_date,
      '',
    }
    for _, line in ipairs(days_content) do
      table.insert(lines, line)
    end
    table.insert(lines, '## Notes')
    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, '## TODO')
    table.insert(lines, '')
    table.insert(lines, '- [ ] ')
  end
  
  vim.cmd('edit ' .. filepath)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.cmd('write')
end

function M.refresh_week()
  open_week_offset(0)
end

function M.open_week()
  open_week_offset(0)
end

function M.open_next_week()
  open_week_offset(1)
end

function M.open_prev_week()
  open_week_offset(-1)
end

local function open_day_from_date(year, month, day, offset)
  local target = os.time({ year = year, month = month, day = day + offset })
  local target_year = os.date('%Y', target)
  local week = get_week_number(target)
  local day_str = os.date('%Y-%m-%d', target)
  local dir = string.format('%s/%s/week%s', base_path, target_year, week)
  local filepath = dir .. '/' .. day_str .. '.md'

  ensure_dir(dir)
  vim.cmd('edit ' .. filepath)

  if vim.fn.filereadable(filepath) == 0 or vim.fn.getfsize(filepath) <= 0 then
    local lines = {
      '# ' .. day_str,
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

function M.open_next_day()
  local filename = vim.fn.expand('%:t:r')
  local y, m, d = filename:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
  if y then
    open_day_from_date(tonumber(y), tonumber(m), tonumber(d), 1)
  else
    open_day(1) -- fallback to tomorrow
  end
end

function M.open_prev_day()
  local filename = vim.fn.expand('%:t:r')
  local y, m, d = filename:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
  if y then
    open_day_from_date(tonumber(y), tonumber(m), tonumber(d), -1)
  else
    open_day(-1) -- fallback to yesterday
  end
end

function M.open_year()
  local year = os.date('%Y')
  local dir = string.format('%s/%s', base_path, year)
  ensure_dir(dir)
  
  local filepath = dir .. '/index.md'
  local weeks = scan_files(dir, '^week%d+$')
  local current_week = tonumber(get_week_number(os.time()))
  
  local existing_lines = read_file_lines(filepath)
  
  -- Build new Weeks section content
  local weeks_content = {}
  table.insert(weeks_content, '## Weeks')
  table.insert(weeks_content, '')
  if #weeks > 0 then
    for _, w in ipairs(weeks) do
      local wnum = tonumber(w:match('week(%d+)'))
      -- Calculate the Monday of this week number
      local jan1 = os.time({ year = tonumber(year), month = 1, day = 1 })
      local jan1_wday = os.date('*t', jan1).wday
      local days_to_monday = (wnum - 1) * 7 - ((jan1_wday + 5) % 7)
      local monday = jan1 + (days_to_monday * 86400)
      local sunday = monday + (6 * 86400)
      local start_date = os.date('%Y-%m-%d', monday)
      local end_date = os.date('%Y-%m-%d', sunday)
      if wnum == current_week then
        table.insert(weeks_content, '- **[Week ' .. wnum .. ': ' .. start_date .. '-' .. end_date .. '](' .. w .. '/index.md) ← THIS WEEK**')
      else
        table.insert(weeks_content, '- [Week ' .. wnum .. ': ' .. start_date .. '-' .. end_date .. '](' .. w .. '/index.md)')
      end
    end
  else
    table.insert(weeks_content, '_No entries yet_')
  end
  table.insert(weeks_content, '')
  
  local lines
  if #existing_lines > 0 then
    local start_idx, end_idx = find_section_range(existing_lines, 'Weeks')
    if start_idx then
      -- Replace existing Weeks section
      lines = {}
      for i = 1, start_idx - 1 do
        table.insert(lines, existing_lines[i])
      end
      for _, line in ipairs(weeks_content) do
        table.insert(lines, line)
      end
      for i = end_idx + 1, #existing_lines do
        table.insert(lines, existing_lines[i])
      end
    else
      -- No Weeks section, insert after header
      lines = { existing_lines[1], '' }
      for _, line in ipairs(weeks_content) do
        table.insert(lines, line)
      end
      for i = 2, #existing_lines do
        table.insert(lines, existing_lines[i])
      end
    end
  else
    -- New file
    lines = {
      '# ' .. year,
      '',
    }
    for _, line in ipairs(weeks_content) do
      table.insert(lines, line)
    end
    table.insert(lines, '## Notes')
    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, '## TODO')
    table.insert(lines, '')
    table.insert(lines, '- [ ] ')
  end
  
  vim.cmd('edit ' .. filepath)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.cmd('write')
end

function M.refresh_year()
  M.open_year()
end

vim.api.nvim_create_user_command('WikiRefreshWeek', function()
  M.refresh_week()
end, { desc = 'Refresh current week index' })

vim.api.nvim_create_user_command('WikiRefreshYear', function()
  M.refresh_year()
end, { desc = 'Refresh current year index' })

vim.api.nvim_create_user_command('WikiNextDay', function()
  M.open_next_day()
end, { desc = 'Open next day diary' })

vim.api.nvim_create_user_command('WikiPrevDay', function()
  M.open_prev_day()
end, { desc = 'Open previous day diary' })

vim.api.nvim_create_user_command('WikiNextWeek', function()
  M.open_next_week()
end, { desc = 'Open next week index' })

vim.api.nvim_create_user_command('WikiPrevWeek', function()
  M.open_prev_week()
end, { desc = 'Open previous week index' })

vim.api.nvim_create_user_command('WikiToday', function()
  M.open_today()
end, { desc = 'Open today diary' })

vim.api.nvim_create_user_command('WikiYesterday', function()
  M.open_yesterday()
end, { desc = 'Open yesterday diary' })

vim.api.nvim_create_user_command('WikiTomorrow', function()
  M.open_tomorrow()
end, { desc = 'Open tomorrow diary' })

vim.api.nvim_create_user_command('WikiWeek', function()
  M.open_week()
end, { desc = 'Open current week index' })

vim.api.nvim_create_user_command('WikiYear', function()
  M.open_year()
end, { desc = 'Open current year index' })

return M

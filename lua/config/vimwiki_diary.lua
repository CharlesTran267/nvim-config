local M = {}

local base_path = '/home/charlestran/vimwiki/diary'
local template_path = '/home/charlestran/vimwiki/diary/note_templates'

local function ensure_dir(path)
  vim.fn.mkdir(path, 'p')
end

local function read_template(name)
  local filepath = template_path .. '/' .. name .. '.md'
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

local function process_template(template_lines, replacements)
  local lines = {}
  for _, line in ipairs(template_lines) do
    local processed = line
    for key, value in pairs(replacements) do
      processed = processed:gsub('{{' .. key .. '}}', value)
    end
    -- Split any embedded newlines into separate lines
    for subline in (processed .. '\n'):gmatch('([^\n]*)\n') do
      table.insert(lines, subline)
    end
  end
  return lines
end

local function create_default_templates()
  ensure_dir(template_path)
  
  -- Week template
  local week_template_path = template_path .. '/week.md'
  if vim.fn.filereadable(week_template_path) == 0 then
    local week_template = {
      '# Week {{week}}: {{start_date}}-{{end_date}}',
      '',
      '## TOC',
      '',
      '- [Notes](#notes)',
      '- [TODO](#todo)',
      '{{day_links}}',
      '',
      '## Notes',
      '',
      '',
      '',
      '## TODO',
      '',
      '- [ ] ',
      '',
      '{{day_sections}}',
    }
    local file = io.open(week_template_path, 'w')
    if file then
      file:write(table.concat(week_template, '\n'))
      file:close()
    end
  end
  
  -- Year template
  local year_template_path = template_path .. '/year.md'
  if vim.fn.filereadable(year_template_path) == 0 then
    local year_template = {
      '# {{year}}',
      '',
      '## TOC',
      '',
      '- [Weeks](#weeks)',
      '- [Notes](#notes)',
      '- [TODO](#todo)',
      '',
      '## Weeks',
      '',
      '{{week_links}}',
      '',
      '## Notes',
      '',
      '',
      '',
      '## TODO',
      '',
      '- [ ] ',
    }
    local file = io.open(year_template_path, 'w')
    if file then
      file:write(table.concat(year_template, '\n'))
      file:close()
    end
  end
  
  -- General template
  local general_template_path = template_path .. '/general.md'
  if vim.fn.filereadable(general_template_path) == 0 then
    local general_template = {
      '# {{title}}',
      '',
      '## Notes',
      '',
      '',
      '',
      '## TODO',
      '',
      '- [ ] ',
    }
    local file = io.open(general_template_path, 'w')
    if file then
      file:write(table.concat(general_template, '\n'))
      file:close()
    end
  end
end

-- Initialize templates on load
create_default_templates()

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

local function get_day_name(date)
  local wday = os.date('*t', date).wday
  local names = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }
  return names[wday]
end

local function update_day_links_today(lines, monday)
  local today = os.date('%Y-%m-%d')
  local updated = {}
  
  for _, line in ipairs(lines) do
    -- Check if this is a day link line
    if line:match('^%- %[') and line:match('%d%d%d%d%-%d%d%-%d%d') then
      -- Remove any existing TODAY marker
      local clean = line:gsub(' ← TODAY', '')
      -- Extract the date from the line
      local date_in_line = clean:match('(%d%d%d%d%-%d%d%-%d%d)')
      if date_in_line == today then
        -- Add TODAY marker before the closing bracket of the link text
        clean = clean:gsub('%]%(#', ' ← TODAY](#')
      end
      table.insert(updated, clean)
    else
      table.insert(updated, line)
    end
  end
  
  return updated
end

local function generate_day_links(monday, today)
  local links = {}
  for i = 0, 6 do
    local day_time = monday + (i * 86400)
    local day_str = os.date('%Y-%m-%d', day_time)
    local day_name = get_day_name(day_time)
    local anchor = string.lower(day_name) .. '-' .. day_str
    local suffix = day_str == today and ' ← TODAY' or ''
    table.insert(links, '- [' .. day_name .. ' ' .. day_str .. suffix .. '](#' .. anchor .. ')')
  end
  return table.concat(links, '\n')
end

local function generate_day_sections(monday, today)
  local sections = {}
  for i = 0, 6 do
    local day_time = monday + (i * 86400)
    local day_str = os.date('%Y-%m-%d', day_time)
    local day_name = get_day_name(day_time)
    table.insert(sections, '## ' .. day_name .. ' ' .. day_str)
    table.insert(sections, '')
    table.insert(sections, '')
    table.insert(sections, '')
  end
  return table.concat(sections, '\n')
end

local function open_week_offset(offset)
  local target = os.time() + (offset * 7 * 86400)
  local year = os.date('%Y', target)
  local week = get_week_number(target)
  local dir = string.format('%s/%s', base_path, year)
  ensure_dir(dir)
  
  -- Calculate week start (Monday) and end (Sunday) dates
  local wday = os.date('*t', target).wday
  local days_since_monday = (wday + 5) % 7
  local monday = target - (days_since_monday * 86400)
  local sunday = monday + (6 * 86400)
  local start_date = os.date('%Y-%m-%d', monday)
  local end_date = os.date('%Y-%m-%d', sunday)
  
  local filepath = dir .. '/week_' .. week .. '.md'
  local today = os.date('%Y-%m-%d')
  
  local existing_lines = read_file_lines(filepath)
  
  if #existing_lines > 0 then
    -- File exists, update TODAY marker and open
    local updated_lines = update_day_links_today(existing_lines, monday)
    vim.cmd('edit ' .. filepath)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, updated_lines)
    vim.cmd('write')
  else
    -- New file - use template
    local template = read_template('week')
    local replacements = {
      week = week,
      start_date = start_date,
      end_date = end_date,
      day_links = generate_day_links(monday, today),
      day_sections = generate_day_sections(monday, today),
    }
    
    local lines = process_template(template, replacements)
    
    vim.cmd('edit ' .. filepath)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd('write')
  end
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

function M.refresh_week()
  open_week_offset(0)
end

local function generate_week_links(dir, year, current_week)
  local weeks = scan_files(dir, '^week_%d+%.md$')
  local links = {}
  
  if #weeks > 0 then
    for _, w in ipairs(weeks) do
      local wnum = tonumber(w:match('week_(%d+)%.md'))
      -- Calculate the Monday of this week number
      local jan1 = os.time({ year = tonumber(year), month = 1, day = 1 })
      local jan1_wday = os.date('*t', jan1).wday
      local days_to_monday = (wnum - 1) * 7 - ((jan1_wday + 5) % 7)
      local monday = jan1 + (days_to_monday * 86400)
      local sunday = monday + (6 * 86400)
      local start_date = os.date('%Y-%m-%d', monday)
      local end_date = os.date('%Y-%m-%d', sunday)
      if wnum == current_week then
        table.insert(links, '- **[Week ' .. wnum .. ': ' .. start_date .. '-' .. end_date .. '](' .. w .. ') ← THIS WEEK**')
      else
        table.insert(links, '- [Week ' .. wnum .. ': ' .. start_date .. '-' .. end_date .. '](' .. w .. ')')
      end
    end
  else
    table.insert(links, '_No entries yet_')
  end
  
  return table.concat(links, '\n')
end

function M.open_year()
  local year = os.date('%Y')
  local dir = string.format('%s/%s', base_path, year)
  ensure_dir(dir)
  
  local filepath = dir .. '/index.md'
  local current_week = tonumber(get_week_number(os.time()))
  
  local existing_lines = read_file_lines(filepath)
  
  local week_links = generate_week_links(dir, year, current_week)
  
  local lines
  if #existing_lines > 0 then
    -- Build new Weeks section content
    local weeks_content_lines = { '## Weeks', '' }
    for link in (week_links .. '\n'):gmatch('([^\n]*)\n') do
      table.insert(weeks_content_lines, link)
    end
    table.insert(weeks_content_lines, '')
    
    local start_idx, end_idx = find_section_range(existing_lines, 'Weeks')
    if start_idx then
      -- Replace existing Weeks section
      lines = {}
      for i = 1, start_idx - 1 do
        table.insert(lines, existing_lines[i])
      end
      for _, line in ipairs(weeks_content_lines) do
        table.insert(lines, line)
      end
      for i = end_idx + 1, #existing_lines do
        table.insert(lines, existing_lines[i])
      end
    else
      -- No Weeks section, insert after header
      lines = { existing_lines[1], '' }
      for _, line in ipairs(weeks_content_lines) do
        table.insert(lines, line)
      end
      for i = 2, #existing_lines do
        table.insert(lines, existing_lines[i])
      end
    end
  else
    -- New file - use template
    local template = read_template('year')
    local replacements = {
      year = year,
      week_links = week_links,
    }
    
    lines = process_template(template, replacements)
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

vim.api.nvim_create_user_command('WikiNextWeek', function()
  M.open_next_week()
end, { desc = 'Open next week index' })

vim.api.nvim_create_user_command('WikiPrevWeek', function()
  M.open_prev_week()
end, { desc = 'Open previous week index' })

vim.api.nvim_create_user_command('WikiWeek', function()
  M.open_week()
end, { desc = 'Open current week index' })

vim.api.nvim_create_user_command('WikiYear', function()
  M.open_year()
end, { desc = 'Open current year index' })

return M

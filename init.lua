local env, theme, _GET, tonumber, ceil = env, theme, _GET, tonumber, math.ceil
local tinsert, tconcat, pairs, debug = table.insert, table.concat, pairs, debug
local pager, l, page_set_title, arg = pager, l, page_set_title, arg
local tonumber, format_date, ophal, read = tonumber, format_date, ophal, io.read
local empty, add_js, _SESSION = seawolf.variable.empty, add_js, _SESSION
local header, json, type, time = header, require 'dkjson', type, os.time
local error = error

module 'ophal.modules.content'

local user_load

--[[
  Implements hook_init().
]]
function init()
  db_query = env.db_query
  user_load = ophal.modules.user.user_load
  user_access = ophal.modules.user.user_access
  user_is_logged_in = ophal.modules.user.user_is_logged_in
end

--[[
  Implements hook_menu().
]]
function menu()
  items = {}
  items.content = {
    page_callback = 'router',
  }
  items['content/save'] = {
    page_callback = 'save_service',
  }
  return items
end

function content_load(id)
  id = tonumber(id or 0)

  rs, err = db_query('SELECT id, title, teaser, body, status, created FROM content WHERE id = ?', id)
  if err then
    error(err)
  end

  return rs:fetch(true)
end

function save_service()
  local input, parsed, pos, err, output, account

  if not user_is_logged_in() then
    header('status', 401)
  else
    header('content-type', 'application/json; charset=utf-8')

    output = {edited = false}
    input = read '*a'
    parsed, pos, err = json.decode(input, 1, nil)
    if err then
      error(err)
    elseif
      not user_access 'administer content'
    then
      header('status', 401)
    elseif
      'table' == type(parsed) and not empty(parsed.id)
    then
      content = content_load(parsed.id)
      if empty(content) then
        error 'No such content.'
      else
        -- Save data
        rs, err = db_query('UPDATE content SET title = ?, teaser = ?, body = ?, changed = ? WHERE id = ?', parsed.title, parsed.teaser, parsed.body, time(), parsed.id)
        if err then
          error(err)
        else
          output.content_id = parsed.id
          output.edited = true
        end
      end
    end

    output = json.encode(output)
  end

  theme.html = function () return output or '' end
end

function router()
  local rs, err, ipp, current_page, num_pages, count, content, id

  id = arg(1)
  if not empty(id) then
    content = content_load(id)

    if arg(2) == 'edit' then
      if not user_is_logged_in() then
        header('status', 401)
      end

      add_js 'misc/jquery.js'
      add_js 'misc/json2.js'
      add_js 'modules/content/content.js'
      page_set_title('Edit "' .. content.title .. '"')

      return theme.content_form(content)
    else
      page_set_title(content.title)
      return theme.content_page(content)
    end
  else
    return frontpage()
  end
end

function frontpage()
  local rows = {}
  local rs, err, count, current_page, ipp, num_pages

  -- Count rows
  rs, err = db_query 'SELECT count(*) FROM content WHERE status = 1 AND promote = 1 ORDER BY created DESC'
  if err then
    error(err)
  else
    count = (rs:fetch() or {})[1]
  end

  -- Calculate current page
  current_page = tonumber(_GET.page) or 1
  ipp = 20
  num_pages = ceil(count/ipp)

  -- Render list
  rs, err = db_query('SELECT * FROM content WHERE status = 1 ORDER BY created DESC LIMIT ?, ?', (current_page -1)*ipp, ipp)
  if err then
    error(err)
  else
    for row in rs:rows(true) do
      tinsert(rows, theme.content_teaser(row))
    end
  end

  return theme.content_frontpage(rows) .. (num_pages > 1 and theme.pager(pager('frontpage', num_pages, current_page)) or '')
end

function theme.content_page(content)
  local output = {
    '<div class="content-page">',
    '<div class="submitted">Submitted by ', '', ' on ', format_date(content.created), '</div>',
    content.teaser or '', [[
]],
    content.body or '',
    theme.content_links(content, true),
    '</div>',
  }

  return tconcat(output)
end

function theme.content_teaser(content)
  local output = {
    '<div class="content-teaser">',
    '<h2>', l(content.title, 'content/' .. content.id), '</h2>',
    content.teaser or '',
    theme.content_links(content),
    '</div>',
  }

  return tconcat(output)
end

function theme.content_links(content, page)
  if page == nil then page = false end

  local links = {}

  if not page then
    tinsert(links, l('Read more', 'content/' .. content.id))
  end

  if user_is_logged_in() then
    tinsert(links, l('edit', 'content/' .. content.id .. '/edit'))
  end
  return theme.item_list{list = links, class = 'content-links'}
end

function theme.content_frontpage(rows)
  local output = {}

  for _, row in pairs(rows) do
    tinsert(output, row)
  end

  return tconcat(output)
end

function theme.content_form(content)
  local row = '<tr><td class="field-name" valign="top">%s:</td><td>%s</td></tr>'

  return tconcat{
		'<form method="POST">',
    '<div id="content_edit_form"><table class="form">',
    theme.hidden{attributes = {id = 'content_id'}, value = content.id},
    row:format('Title', theme.textfield{attributes = {id = 'content_title', size = 60}, value = content.title}),
    row:format('Teaser', theme.textarea{attributes = {id = 'content_teaser', cols = 60, rows = 10}, value = content.teaser}),
    row:format('Body', theme.textarea{attributes = {id = 'content_body', cols = 60, rows = 15}, value = content.body}),
    row:format('Status', empty(content.status) and 'Unplished' or 'Published'),
    row:format('Created on', format_date(content.created)),
    ('<tr><td colspan="2" align="right">%s</td></tr>'):format(theme.button{attributes = {id = 'save_submit'}, value = 'Save'}),
    '</table></div>',
		'</form>',
  }
end

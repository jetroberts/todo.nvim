local M = {}

local window = 0
local buf = 0

local minHeight = 40
local minWidth = 40

local percentage_height = 0.7
local percentage_width = 0.7

local function prependLine()
  local current_line = vim.api.nvim_get_current_line()
  if current_line == "" then
    print("This line is currently empty!")
    vim.api.nvim_set_current_line("[ ] ")

    local line_length = #vim.api.nvim_get_current_line()
    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], line_length })
  end
end

function M.markDone()
  local current_line = vim.api.nvim_get_current_line()
  local new_line = string.gsub(current_line, "%[ %]", "[X]")
  vim.api.nvim_set_current_line(new_line)
end

local function otherWindowOpen()
  local window_ids = vim.api.nvim_list_wins()
  for _, window_id in ipairs(window_ids) do
    local win = vim.api.nvim_win_get_config(window_id)
    if win.relative ~= "" then
      return true
    end
  end

  return false
end

function M.openWindow(filepath)
  if otherWindowOpen() then
    print("There was another floating window")
    return
  end

  if not M.isBufferOpen(filepath) then
    buf = vim.api.nvim_create_buf(false, false)
  end

  vim.api.nvim_buf_call(buf, function()
    vim.cmd.edit(filepath)
  end)

  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * percentage_width)
  local height = math.floor(ui.height * percentage_height)

  local current_height = vim.api.nvim_get_option_value("lines", {})
  local current_width = vim.api.nvim_get_option_value("columns", {})

  local row = math.floor((current_height - height) / 2)
  local col = math.floor((current_width - width) / 2)

  window = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    border = 'rounded',
  })

  vim.api.nvim_create_autocmd({ "TextChangedI" }, {
    callback = function()
      prependLine()
    end,
    buffer = buf
  })
end

function M.closeWindow(filepath)
  if not vim.api.nvim_win_is_valid(window) then
    window = 0
    return
  end

  if vim.api.nvim_buf_get_name(buf) == "" then
    vim.api.nvim_buf_set_name(buf, filepath)
  end

  vim.api.nvim_buf_call(buf, function()
    vim.api.nvim_command("write!")
  end)


  vim.api.nvim_win_close(window, false)
  window = 0
end

function M.setup()
  local filename = 'state.todo'
  local statepath = vim.fn.stdpath('state')
  local filepath = statepath .. "/" .. filename

  vim.keymap.set("n", "<Leader>t", function()
    if window ~= 0 then
      M.closeWindow(filepath)
    else
      M.openWindow(filepath)
    end
  end
  )

  vim.keymap.set("n", "<Leader>g", function()
    M.markDone()
  end)
end

function M.isBufferOpen(filepath)
  local buffers = vim.api.nvim_list_bufs()

  for _, bufnr in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local buf_name = vim.api.nvim_buf_get_name(bufnr)
      if buf_name == filepath then
        return true
      end
    end
  end

  return false
end

return M

local M = {}

---Opens content in a new, modifiable scratch buffer.
---@param content string The content to write to the buffer.
function M.open_in_buffer(content)
  -- Create a new scratch buffer that will be listed
  local bufnr = vim.api.nvim_create_buf(true, true)

  -- Open the new buffer in the current window
  vim.api.nvim_win_set_buf(0, bufnr)

  -- Set options for the new buffer
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "http")

  local lines = vim.split(content, "\n")
  -- Set the content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Move cursor to the first actual request line
  local first_request_line = -1
  for i, line in ipairs(lines) do
    -- Find the first line that looks like a request line (METHOD {{baseUrl}}...)
    if line:match("^[A-Z]+%s+{{baseUrl}}") then
      first_request_line = i
      break
    end
  end

  if first_request_line > 0 then
    vim.api.nvim_win_set_cursor(0, { first_request_line, 0 })
  end
end

---A simple JSON pretty-printer.
---@param compact_json string A compact JSON string.
---@return string A formatted JSON string.
function M.pretty_print_json(compact_json)
  local indent_char = "  "
  local level = 0
  local result = ""
  local in_string = false

  for i = 1, #compact_json do
    local char = compact_json:sub(i, i)
    local prev_char = i > 1 and compact_json:sub(i - 1, i - 1) or nil

    -- User corrected escaping for me, so I am keeping it.
    if char == '"' and (not prev_char or prev_char ~= "\\") then
      in_string = not in_string
    end

    if not in_string then
      if char == "{" or char == "[" then
        result = result .. char .. "\n" .. string.rep(indent_char, level + 1)
        level = level + 1
      elseif char == "}" or char == "]" then
        level = level - 1
        result = result .. "\n" .. string.rep(indent_char, level) .. char
      elseif char == "," then
        result = result .. char .. "\n" .. string.rep(indent_char, level)
      elseif char == ":" then
        result = result .. char .. " "
      elseif not char:match("\\s") then
        result = result .. char
      end
    else
      result = result .. char
    end
  end
  return result
end

---Resolves a $ref JSON pointer string within the spec.
---@param spec table The full OpenAPI specification.
---@param ref_string string The reference string, e.g., "#/components/schemas/User".
---@return table|nil The resolved schema object or nil if not found.
function M.resolve_ref(spec, ref_string)
  if not ref_string or not ref_string:match("^#/") then
    return nil
  end

  local parts = vim.split(ref_string, "/", { trimempty = true })
  table.remove(parts, 1) -- Remove the leading #

  local current = spec
  for _, part in ipairs(parts) do
    if type(current) == "table" and current[part] then
      current = current[part]
    else
      return nil -- Invalid path
    end
  end
  return current
end

return M


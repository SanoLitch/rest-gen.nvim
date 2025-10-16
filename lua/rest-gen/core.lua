local core = {}

---Loads the specification from a given source (URL or local path).
---@param source string The URL or file path of the OpenAPI/Swagger specification.
---@param callback function The function to call with the parsed data or an error.
function core.load_spec(source, callback)
  -- Foundation for caching (to be implemented later)
  -- local cached = get_from_cache(source)
  -- if cached then
  --   callback(cached)
  --   return
  -- end

  if source:match("^http") then
    core.load_from_url(source, callback)
  else
    core.load_from_file(source, callback)
  end
end

---Loads a spec from a URL.
---@param url string
---@param callback function
function core.load_from_url(url, callback)
  local curl = require("plenary.curl")
  curl.get(url, {
    callback = function(response)
      if response.exit ~= 0 or response.status < 200 or response.status >= 300 then
        vim.schedule(function()
          callback(nil, "Error fetching from URL " .. url .. ". Status: " .. response.status)
        end)
        return
      end
      local ok, data = pcall(vim.json.decode, response.body)
      if not ok then
        local preview = vim.fn.strcharpart(response.body, 0, 200)
        vim.schedule(function()
          callback(nil, "Failed to parse JSON from " .. url .. ". Response body starts with: " .. preview)
        end)
        return
      end
      vim.schedule(function()
        callback(data)
      end)
    end,
  })
end

---Loads a spec from a local file.
---@param path string
---@param callback function
function core.load_from_file(path, callback)
  -- Foundation for YAML (to be implemented later)
  if path:match("%.ya?ml$") then
    callback(nil, "YAML parsing is not implemented yet.")
    -- Here we would call `yq` and parse the output
    return
  end

  if not path:match("%.json$") then
    callback(nil, "Unsupported file type. Only .json is supported for now.")
    return
  end

  local file = io.open(path, "r")
  if not file then
    callback(nil, "File not found: " .. path)
    return
  end

  local content = file:read("*a")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    callback(nil, "Failed to parse JSON from file " .. path)
    return
  end
  callback(data)
end

return core

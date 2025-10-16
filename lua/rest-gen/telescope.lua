local M = {}

local core = require("swagger-rest.core")
local parser = require("swagger-rest.parser")
local generator = require("swagger-rest.generator")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local utils = require("swagger-rest.utils")

---
--Opens the Telescope picker to select an endpoint.
---@param source string The source of the OpenAPI spec.
function M.picker(source)
  core.load_spec(source, function(spec_data, err)
    if err then
      vim.notify("Swagger-REST Error: " .. err, vim.log.levels.ERROR)
      return
    end

    local endpoints, security_schemes = parser.parse(spec_data)

    local function entry_maker(entry)
      local display = string.format("[%s] %s", entry.method, entry.path)
      if entry.contentType then
        display = display .. " (" .. entry.contentType .. ")"
      end
      return {
        value = entry,
        display = display,
        ordinal = string.format("%s %s %s", entry.path, entry.method, entry.contentType or ""),
      }
    end

    pickers
      .new({}, {
        prompt_title = "Swagger Endpoints",
        finder = finders.new_table({
          results = endpoints,
          entry_maker = entry_maker,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then
              local http_content = generator.generate_single(selection.value, security_schemes, spec_data)
              utils.open_in_buffer(http_content)
            end
          end)
          return true
        end,
      })
      :find()
  end)
end

return M

local M = {}

local core = require("rest-gen.core")
local parser = require("rest-gen.parser")
local generator = require("rest-gen.generator")
local telescope_picker = require("rest-gen.telescope")

local config = {
  default_source = "https://petstore3.swagger.io/v3/openapi.json",
  keymaps = {
    picker_default = "<leader>hr",
    picker_input = "<leader>hR",
  },
}

local utils = require("rest-gen.utils")

local function picker_with_input()
  vim.ui.input({ prompt = "Swagger Source URL or Path: " }, function(source)
    if source and source ~= "" then
      telescope_picker.picker(source)
    end
  end)
end

local function set_keymaps()
  if config.keymaps.picker_default then
    vim.keymap.set("n", config.keymaps.picker_default, function()
      telescope_picker.picker(config.default_source)
    end, { desc = "[Swagger] Pick from default source" })
  end
  if config.keymaps.picker_input then
    vim.keymap.set("n", config.keymaps.picker_input, picker_with_input, { desc = "[Swagger] Pick from input" })
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  vim.api.nvim_create_user_command("SwaggerRestPick", function(cmd_opts)
    local source = cmd_opts.args
    if not source or source == "" then
      picker_with_input()
      return
    end
    telescope_picker.picker(source)
  end, { nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("SwaggerRest", function(cmd_opts)
    local source = cmd_opts.args
    if not source or source == "" then
      vim.notify("Swagger-REST: Source is required (URL or file path)", vim.log.levels.WARN)
      return
    end
    core.load_spec(source, function(spec_data, err)
      if err then
        vim.notify("Swagger-REST Error: " .. err, vim.log.levels.ERROR)
        return
      end
      local endpoints, security_schemes = parser.parse(spec_data)
      local http_content = generator.generate_all(endpoints, security_schemes, spec_data)
      utils.open_in_buffer(http_content)
    end)
  end, { nargs = "?", complete = "file" })

  set_keymaps()
end

return M

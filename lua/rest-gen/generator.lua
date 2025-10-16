local M = {}
local utils = require("swagger-rest.utils")

-- Forward declaration
local get_endpoint_request

---Recursively builds an example object from a schema.
---@param schema table The schema object to process.
---@param spec table The full OpenAPI specification for resolving refs.
---@return any A generated example value.
local function generate_example_from_schema(schema, spec)
  -- Forward declaration for mutual recursion
  local generate_example

  generate_example = function(sch, s)
    if not sch then
      return nil
    end

    -- Base Case 1: The schema itself has a top-level example.
    if sch.example ~= nil then
      return sch.example
    end

    -- Base Case 2: The schema is a direct reference to another.
    if sch["$ref"] then
      local resolved = utils.resolve_ref(s, sch["$ref"])
      return generate_example(resolved, s)
    end

    -- Recursive Step for Objects
    if sch.type == "object" and sch.properties then
      local obj = {}
      for prop_name, prop_schema in pairs(sch.properties) do
        obj[prop_name] = generate_example(prop_schema, s)
      end
      return obj
    end

    -- Recursive Step for Arrays
    if sch.type == "array" and sch.items then
      -- Generate one example item for the array and wrap it in a table.
      local item = generate_example(sch.items, s)
      return { item }
    end

    -- Base Case 3: Simple types with no example.
    if sch.type == "string" then
      return ""
    end
    if sch.type == "number" or sch.type == "integer" then
      return 0
    end
    if sch.type == "boolean" then
      return false
    end

    return nil -- Placeholder for unknown types
  end

  return generate_example(schema, spec)
end

---Generates a request body based on the content type.
local function generate_request_body(content_type, content_data, spec)
  if content_type == "application/json" then
    local example_data = generate_example_from_schema(content_data.schema, spec)
    if example_data then
      local ok, compact_json = pcall(vim.json.encode, example_data)
      if ok then
        return utils.pretty_print_json(compact_json)
      end
    end
    return "{}\n"
  elseif content_type == "application/x-www-form-urlencoded" then
    local schema = content_data.schema
    if schema and schema["$ref"] then
      schema = utils.resolve_ref(spec, schema["$ref"])
    end
    if schema and schema.properties then
      local form_fields = {}
      for prop_name, _ in pairs(schema.properties) do
        table.insert(form_fields, prop_name .. "={{" .. prop_name .. "}}")
      end
      return table.concat(form_fields, "& ")
    end
    return "key={{key}}&value={{value}}"
  else
    -- Fallback for unsupported content types
    return "# TODO: Provide body for content type: " .. content_type
  end
end

local function get_security_definitions(security_schemes)
  local lines = {}
  for name, scheme in pairs(security_schemes) do
    if scheme.scheme == "bearer" then
      table.insert(lines, "@token = {{BEARER_TOKEN}}")
    elseif scheme.type == "apiKey" then
      table.insert(lines, "@" .. scheme.type .. " = ")
    end
  end
  return table.concat(lines, "\n")
end

local function process_path_and_query(endpoint)
  local path = endpoint.path
  local query_params = {}

  for _, param in ipairs(endpoint.parameters or {}) do
    if param["in"] == "path" then
      path = path:gsub("{" .. param.name .. "}", "{{" .. param.name .. "}}")
    elseif param["in"] == "query" then
      table.insert(query_params, param.name .. "={{" .. param.name .. "}}")
    end
  end

  local query_string = ""
  if #query_params > 0 then
    query_string = "?" .. table.concat(query_params, "&")
  end

  return path, query_string
end

get_endpoint_request = function(endpoint, security_schemes, spec)
  local lines = {}
  local path, query_string = process_path_and_query(endpoint)
  local security_query_params = {}

  table.insert(lines, "###")
  table.insert(lines, "# @summary " .. endpoint.summary)
  if endpoint.operationId then
    table.insert(lines, "# @operationId " .. endpoint.operationId)
  end
  table.insert(lines, "###")

  -- Security Processing
  local security_headers = {}
  if endpoint.security then
    for _, sec_req in ipairs(endpoint.security) do
      for sec_name, _ in pairs(sec_req) do
        local scheme = security_schemes[sec_name]
        if scheme then
          if scheme.scheme == "bearer" then
            table.insert(security_headers, "Authorization: Bearer {{token}}")
          elseif scheme.type == "apiKey" then
            local var_name = scheme.type
            if scheme["in"] == "header" then
              table.insert(security_headers, scheme.name .. ": {{" .. var_name .. "}}")
            elseif scheme["in"] == "query" then
              table.insert(security_query_params, scheme.name .. "={{" .. var_name .. "}}")
            elseif scheme["in"] == "cookie" then
              table.insert(security_headers, "Cookie: " .. scheme.name .. "={{" .. var_name .. "}}")
            end
          elseif scheme.type == "oauth2" then
            table.insert(security_headers, "# TODO: This endpoint is protected by OAuth2. Manual setup required.")
          end
        end
      end
    end
  end

  -- Finalize query string
  if #security_query_params > 0 then
    if query_string == "" then
      query_string = "?"
    else
      query_string = query_string .. "&"
    end
    query_string = query_string .. table.concat(security_query_params, "&")
  end

  -- Build Request
  table.insert(lines, endpoint.method .. " {{baseUrl}}" .. path .. query_string)
  vim.list_extend(lines, security_headers)

  if endpoint.contentType and endpoint.contentData then
    table.insert(lines, "Content-Type: " .. endpoint.contentType)
    table.insert(lines, "")
    table.insert(lines, generate_request_body(endpoint.contentType, endpoint.contentData, spec))
  end

  return table.concat(lines, "\n")
end

local function generate_http_content(endpoints, security_schemes, spec)
  local content = {}
  table.insert(content, "@baseUrl = {{BASE_URL}}")

  local security_defs = get_security_definitions(security_schemes)
  if security_defs ~= "" then
    table.insert(content, security_defs)
  end

  local all_vars = {}
  local seen_vars = {}
  for _, endpoint in ipairs(endpoints) do
    -- Add path and query params to variables
    for _, param in ipairs(endpoint.parameters or {}) do
      if param and param.name and not seen_vars[param.name] then
        table.insert(all_vars, "@" .. param.name .. " = ")
        seen_vars[param.name] = true
      end
    end
  end

  if #all_vars > 0 then
    table.insert(content, "\n" .. table.concat(all_vars, "\n"))
  end

  for _, endpoint in ipairs(endpoints) do
    table.insert(content, "\n")
    table.insert(content, get_endpoint_request(endpoint, security_schemes, spec))
  end

  return table.concat(content, "\n")
end

function M.generate_all(endpoints, security_schemes, spec)
  return generate_http_content(endpoints, security_schemes, spec)
end

function M.generate_single(endpoint, security_schemes, spec)
  return generate_http_content({ endpoint }, security_schemes, spec)
end

return M


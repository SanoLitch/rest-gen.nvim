local M = {}

---Parses the OpenAPI/Swagger specification to extract endpoints.
---@param spec table The decoded JSON specification.
---@return table endpoints A list of endpoints with method, path, etc.
---@return table|nil security_schemes Information about security schemes.
function M.parse(spec)
  local endpoints = {}
  local security_schemes = (spec.components and spec.components.securitySchemes) or spec.securityDefinitions or {}

  for path, path_item in pairs(spec.paths or {}) do
    for method, operation in pairs(path_item) do
      local valid_methods = { "get", "post", "put", "patch", "delete", "head", "options", "trace" }
      if vim.tbl_contains(valid_methods, method:lower()) then
        -- If there's a request body with multiple content types, create an entry for each.
        if operation.requestBody and operation.requestBody.content then
          for content_type, content_data in pairs(operation.requestBody.content) do
            local endpoint = {
              path = path,
              method = method:upper(),
              summary = operation.summary or "",
              description = operation.description or "",
              operationId = operation.operationId,
              parameters = operation.parameters or {},
              security = operation.security or spec.security,
              -- New fields for selected content type
              contentType = content_type,
              contentData = content_data,
            }
            table.insert(endpoints, endpoint)
          end
        else
          -- If no request body, create a single entry.
          local endpoint = {
            path = path,
            method = method:upper(),
            summary = operation.summary or "",
            description = operation.description or "",
            operationId = operation.operationId,
            parameters = operation.parameters or {},
            security = operation.security or spec.security,
            contentType = nil, -- No content type
            contentData = nil,
          }
          table.insert(endpoints, endpoint)
        end
      end
    end
  end

  table.sort(endpoints, function(a, b)
    if a.path == b.path then
      if a.method == b.method then
        return (a.contentType or "") < (b.contentType or "")
      end
      return a.method < b.method
    end
    return a.path < b.path
  end)

  return endpoints, security_schemes
end

return M

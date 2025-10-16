rest-gen.nvim

**Automatically generate HTTP requests for `rest.nvim` from your OpenAPI/Swagger specifications.**

This Neovim plugin saves you from the hassle of manually creating and maintaining `.http` files. It reads your OpenAPI/Swagger specification (local or remote) and generates ready-to-use requests directly in your editor.

<!-- TODO: Insert a GIF demonstration here -->
<!-- ![swagger-rest.nvim Demo](link_to_your_gif.gif) -->

---

## ✨ Features

- **On-the-Fly Generation**: Create HTTP requests without storing `.http` files in your project.
- **Multiple Sources Supported**:
  - Remote URLs (`http://...` or `https://...`).
  - Local files (`.json`).
- **Telescope Integration**: A convenient picker to search and select endpoints.
- **Content-Type Selection**: If an endpoint supports multiple content types (`application/json`, `application/x-www-form-urlencoded`, etc.), the plugin will prompt you to choose one.
- **Intelligent Body Generation**:
  - Recursively builds complex JSON objects from examples, supporting nested schemas (`$ref`).
  - Generates request bodies for `x-www-form-urlencoded` requests.
- **Authorization Support**: Automatically generates variables and headers for `Bearer Token` and `apiKey` (in `header`, `query`, or `cookie`).
- **Full `rest.nvim` Compatibility**: Uses standard variable syntax and `.http` file structure.

## 📋 Requirements

- Neovim 0.11+
- [rest-nvim/rest.nvim](https://github.com/rest-nvim/rest.nvim)
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- In your plugins file
return {
  "your-github-username/swagger-rest.nvim",
  dependencies = { "rest-nvim/rest.nvim", "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  -- Example configuration (optional)
  opts = {
    -- Default URL or file path to be used
    default_source = "https://petstore3.swagger.io/api/v3/openapi.json",
    -- Keymaps
    keymaps = {
      picker_default = "<leader>hr", -- Open Telescope with the default_source
      picker_input = "<leader>hR",   -- Open Telescope with a manual source prompt
    },
  },
  config = function(_, opts)
    require("swagger-rest").setup(opts)
  end,
}
```

## ⚙️ Usage

### Commands

- `:SwaggerRestPick <source>`: Opens a Telescope picker to select an endpoint from the specified source (URL or file path).
  - *Example*: `:SwaggerRestPick https://petstore3.swagger.io/api/v3/openapi.json`
  - If `<source>` is omitted, a prompt will appear for manual input.

- `:SwaggerRest <source>`: Generates a full `.http` file with all endpoints from the specified source.
  - *Example*: `:SwaggerRest /path/to/your/local/spec.json`

### Default Keymaps

- `<leader>hr`: Opens Telescope with endpoints from the `default_source` specified in your configuration.
- `<leader>hR`: Opens a prompt to enter a URL or file path for a specification, then opens Telescope.

## 📄 License

This plugin is distributed under the MIT License. See the `LICENSE` file for more details.
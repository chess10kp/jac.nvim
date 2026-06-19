---@module "jac.treesitter"
---Integration with nvim-treesitter for Jac syntax highlighting, folding, and indentation.
---
---Usage:
---```lua
---require("jac").setup({
---  treesitter = true,  -- auto-register and optionally auto-install the parser
---})
---```
---
---Or standalone:
---```lua
---require("jac.treesitter").setup()
---```
---
---This registers the Jac tree-sitter parser with nvim-treesitter using the modern
---`local_parsers` approach. The parser is hosted at:
---https://github.com/jaseci-labs/tree-sitter-jac
---
---Note: The parser requires both src/parser.c and src/scanner.c (external scanner
---for f-strings, JSX text, and ::py:: blocks).

local M = {}

---Default configuration
---@class jac.TreesitterConfig
---@field auto_install boolean Automatically install the parser if not present (default: false)
---@field enable boolean Enable treesitter integration (default: true)

M.config = {
  auto_install = false,
  enable = true,
}

---Check if nvim-treesitter is available
---@return boolean
local function treesitter_available()
  return pcall(require, "nvim-treesitter")
end

---Check if the Jac parser is already installed
---@return boolean
local function parser_installed()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return false
  end
  return parsers.has_parser("jac")
end

---Register the Jac parser using the modern local_parsers approach
local function register_parser()
  local ok, treesitter = pcall(require, "nvim-treesitter")
  if not ok then
    vim.notify(
      "[jac.nvim] Failed to load nvim-treesitter",
      vim.log.levels.ERROR
    )
    return false
  end

  -- Use the modern local_parsers API
  local local_parsers = treesitter.configs.local_parsers or {}
  
  -- Only add if not already registered
  if not local_parsers.jac then
    treesitter.configs.local_parsers = {
      jac = {
        source = {
          type = "self_contained",
          url = "https://github.com/jaseci-labs/tree-sitter-jac",
          semver = false,
          -- The parser ships its own queries in the queries/ directory
          queries_path = "queries/jac",
        },
        filetypes = { "jac" },
      },
    }
  end

  return true
end

---Install the Jac tree-sitter parser
---@return boolean success
local function install_parser()
  if not treesitter_available() then
    vim.notify(
      "[jac.nvim] nvim-treesitter is not available. Install it first.",
      vim.log.levels.ERROR
    )
    return false
  end

  if parser_installed() then
    return true
  end

  local ok, install = pcall(require, "nvim-treesitter.install")
  if not ok then
    vim.notify(
      "[jac.nvim] Failed to load nvim-treesitter.install",
      vim.log.levels.ERROR
    )
    return false
  end

  vim.notify("[jac.nvim] Installing Jac tree-sitter parser...", vim.log.levels.INFO)

  -- Install the parser asynchronously
  install.install("jac", {
    with_sync = false,
  })

  return true
end

---Setup Jac tree-sitter integration
---@param opts? jac.TreesitterConfig
function M.setup(opts)
  opts = opts or {}

  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("keep", opts, M.config)

  if not M.config.enable then
    return
  end

  if not treesitter_available() then
    vim.notify(
      "[jac.nvim] nvim-treesitter is not available. Install it to use tree-sitter features.",
      vim.log.levels.WARN
    )
    return
  end

  -- Register the parser configuration
  if not register_parser() then
    return
  end

  -- Auto-install if configured
  if M.config.auto_install and not parser_installed() then
    install_parser()
  end
end

---Manually install the Jac parser (can be called by user)
function M.install()
  if not treesitter_available() then
    vim.notify(
      "[jac.nvim] nvim-treesitter is not available. Install it first.",
      vim.log.levels.ERROR
    )
    return
  end

  if not register_parser() then
    return
  end

  install_parser()
end

return M

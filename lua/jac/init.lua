---@module "jac"

local M = {}

---Default configuration
---@class jac.Config
---@field auto_start boolean Automatically start the LSP when a .jac file is opened (default: true)
---@field capabilities? table LSP client capabilities (from nvim-cmp or similar)
---@field on_attach? fun(client: table, bufnr: integer) LSP on_attach callback
---@field settings? table LSP server settings
---@field flags? table LSP client flags
---@field cmp? boolean|table Auto-configure nvim-cmp integration (default: false). Set to `true` for defaults, or pass a table with `{ capabilities = ... }` to customize.
---@field blink? boolean|table Auto-configure blink.cmp integration (default: false). Set to `true` for defaults, or pass a table with `{ capabilities = ... }` to customize.
---@field coq? boolean Auto-configure coq_nvim integration (default: false). Set to `true` to wrap LSP setup with coq.lsp_ensure_capabilities().

M.config = {
  auto_start = true,
  capabilities = nil,
  on_attach = nil,
  settings = {},
  flags = nil,
  cmp = false,
  blink = false,
  coq = false,
}

-- Internal flag to track whether setup has been called
M._initialized = false

---Try to load a module and return it, or nil if not available.
---@param name string
---@return table|nil
local function try_require(name)
  local ok, mod = pcall(require, name)
  return ok and mod or nil
end

---Attempt to auto-wire nvim-cmp capabilities into the config.
---@param cmp_opts boolean|table User-provided cmp option
local function setup_cmp(cmp_opts)
  if not cmp_opts then
    return
  end

  local cmp_nvim_lsp = try_require("cmp_nvim_lsp")
  if not cmp_nvim_lsp then
    vim.notify(
      "[jac.nvim] cmp_nvim_lsp not found. Install hrsh7th/cmp-nvim-lsp for nvim-cmp integration.",
      vim.log.levels.WARN
    )
    return
  end

  local caps = type(cmp_opts) == "table" and cmp_opts.capabilities or cmp_nvim_lsp.default_capabilities()
  M.config.capabilities = vim.tbl_deep_extend("keep", M.config.capabilities or {}, caps)
  M.config.cmp = true
end

---Attempt to auto-wire blink.cmp capabilities into the config.
---@param blink_opts boolean|table User-provided blink option
local function setup_blink(blink_opts)
  if not blink_opts then
    return
  end

  local blink = try_require("blink.cmp")
  if not blink then
    vim.notify(
      "[jac.nvim] blink.cmp not found. Install saghen/blink.cmp for blink.cmp integration.",
      vim.log.levels.WARN
    )
    return
  end

  local caps = type(blink_opts) == "table" and blink_opts.capabilities or blink.get_lsp_capabilities()
  M.config.capabilities = vim.tbl_deep_extend("keep", M.config.capabilities or {}, caps)
  M.config.blink = true
end

---Attempt to auto-wire coq_nvim capabilities into the config.
---@param coq_opts boolean User-provided coq option
local function setup_coq(coq_opts)
  if not coq_opts then
    return
  end

  local ok, _ = pcall(require, "coq")
  if not ok then
    vim.notify(
      "[jac.nvim] coq_nvim not found. Install ms-jpq/coq_nvim for coq integration.",
      vim.log.levels.WARN
    )
    return
  end

  M.config.coq = true
end

---Setup jac.nvim with user configuration.
---Call this from your init.lua to configure the plugin.
---
---Usage:
---```lua
---require("jac").setup({
---   auto_start = true,
---   on_attach = function(client, bufnr)
---     -- your custom on_attach logic
---   end,
---   -- nvim-cmp integration:
---   cmp = true,
---   -- or blink.cmp integration:
---   blink = true,
--- })
---```
---@param opts? jac.Config
function M.setup(opts)
  opts = opts or {}

  -- Extract cmp/blink/coq opts before merging (so they don't stay in config)
  local cmp_opts = opts.cmp
  local blink_opts = opts.blink
  local coq_opts = opts.coq

  -- Shallow-copy opts to avoid mutating the caller's table
  local filtered_opts = vim.tbl_deep_extend("keep", {}, opts)
  filtered_opts.cmp = nil
  filtered_opts.blink = nil
  filtered_opts.coq = nil

  M.config = vim.tbl_deep_extend("keep", M.config, filtered_opts)

  -- Apply completion plugin integrations
  setup_cmp(cmp_opts)
  setup_blink(blink_opts)
  setup_coq(coq_opts)

  -- Create an autocmd group for jac.nvim
  local group = vim.api.nvim_create_augroup("JacNvim", { clear = true })

  -- Auto-start LSP when a jac file is opened
  if M.config.auto_start then
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "jac",
      callback = function()
        require("jac.lsp").auto_start()
      end,
      desc = "Auto-start Jac LSP",
    })
  end

  M._initialized = true
end

return M

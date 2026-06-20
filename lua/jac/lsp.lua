---@module "jac.lsp"

local M = {}

---Check if the `jac` CLI is available in PATH
---@return boolean
function M.jac_available()
  return vim.fn.executable("jac") == 1
end

-- Track whether lspconfig.setup() has been called for jac_ls
local _setup_done = false

---Build server options from setup() config and any per-call overrides.
---@param opts? table
---@return table
local function build_server_opts(opts)
  opts = opts or {}

  local config = require("jac").config

  local base = {
    capabilities = config.capabilities,
    on_attach = config.on_attach,
    settings = config.settings,
    flags = config.flags,
  }

  -- Per-call opts override setup() config.
  return vim.tbl_deep_extend("keep", opts, base)
end

---Apply coq_nvim wrapper if configured.
---@param server_opts table
---@return table
local function maybe_apply_coq(server_opts)
  if not require("jac").config.coq then
    return server_opts
  end

  local ok_coq, coq = pcall(require, "coq")
  if not ok_coq then
    return server_opts
  end

  return coq.lsp_ensure_capabilities(server_opts)
end

---Register and start the Jac LSP server.
---Prefers nvim-lspconfig if available, otherwise falls back to vim.lsp.start.
---@param opts? table User configuration overrides
function M.start(opts)
  if not M.jac_available() then
    vim.notify(
      "[jac.nvim] `jac` command not found in PATH. Install jaclang: pip install jaclang",
      vim.log.levels.WARN
    )
    return
  end

  local server_opts = build_server_opts(opts)
  local final_opts = maybe_apply_coq(server_opts)

  local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
  if ok_lspconfig then
    local configs = require("lspconfig.configs")

    -- Register jac_ls if not already registered
    if not configs.jac_ls then
      configs.jac_ls = {
        default_config = {
          cmd = { "jac", "lsp" },
          filetypes = { "jac" },
          root_dir = lspconfig.util.root_pattern(".git", "jac.config.json", ".jacconfig.json", vim.fn.getcwd()),
          single_file_support = true,
        },
        docs = {
          description = [[
https://docs.jaseci.org

Jac is an AI-native, full-stack programming language by Jaseci Labs.

The Jac language server is built into the `jac` CLI. Install with:
  pip install jaclang

Then run `jac lsp` to start the server.
]],
        },
      }
    end

    -- Only call setup() once; lspconfig handles per-buffer attachment after that
    if not _setup_done then
      lspconfig.jac_ls.setup(final_opts)
      _setup_done = true
    end
    return
  end

  -- Fallback: use Neovim's built-in vim.lsp.start directly (per-buffer).
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "jac_ls" })
  if #clients > 0 then
    return
  end

  local root_dir = vim.fs.root(bufnr, { ".git", "jac.config.json", ".jacconfig.json" })
    or vim.fn.getcwd()

  vim.lsp.start({
    name = "jac_ls",
    cmd = { "jac", "lsp" },
    root_dir = root_dir,
    capabilities = final_opts.capabilities,
    on_attach = final_opts.on_attach,
    settings = final_opts.settings,
  })
end

---Auto-start the LSP when a Jac file is opened.
---Should be called from a FileType autocmd or ftplugin.
function M.auto_start()
  -- Only start if not already attached to this buffer
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "jac_ls" })
  if #clients > 0 then
    return
  end

  -- Check if we should auto-start (respect user opt-out)
  local auto_start = require("jac").config.auto_start
  if auto_start == false then
    return
  end

  M.start()
end

return M

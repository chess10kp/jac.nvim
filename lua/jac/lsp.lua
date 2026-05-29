---@module "jac.lsp"

local M = {}

---Check if the `jac` CLI is available in PATH
---@return boolean
function M.jac_available()
  return vim.fn.executable("jac") == 1
end

-- Track whether lspconfig.setup() has been called for jac_ls
local _setup_done = false

---Register and start the Jac LSP server
---@param opts? table User configuration overrides
function M.start(opts)
  opts = opts or {}

  if not M.jac_available() then
    vim.notify(
      "[jac.nvim] `jac` command not found in PATH. Install jaclang: pip install jaclang",
      vim.log.levels.WARN
    )
    return
  end

  local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
  if not ok_lspconfig then
    vim.notify(
      "[jac.nvim] nvim-lspconfig is required. Install: neodev/nvim-lspconfig",
      vim.log.levels.ERROR
    )
    return
  end

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

  -- Build server options: user opts override defaults
  local default_opts = {
    capabilities = nil,
    on_attach = nil,
    settings = {},
  }
  local server_opts = vim.tbl_deep_extend("keep", default_opts, opts)

  -- Only call setup() once; lspconfig handles per-buffer attachment after that
  if not _setup_done then
    -- Apply coq_nvim wrapper if configured (coq wraps the entire server setup table)
    local final_opts = server_opts
    if require("jac").config.coq then
      local ok_coq, coq = pcall(require, "coq")
      if ok_coq then
        final_opts = coq.lsp_ensure_capabilities(server_opts)
      end
    end
    lspconfig.jac_ls.setup(final_opts)
    _setup_done = true
  end
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

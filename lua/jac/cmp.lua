---@module "jac.cmp"
---Integration with nvim-cmp (hrsh7th/nvim-cmp) for Jac LSP completions.
---
---Usage:
---```lua
---require("jac.cmp").setup()
---```
---
---This auto-detects nvim-cmp and cmp-nvim-lsp, then merges the required
---LSP client capabilities into jac.config so the Jac LSP server can
---provide completions, snippets, and documentation through nvim-cmp.

local M = {}

---Wire up nvim-cmp LSP capabilities for the Jac language server.
---
---Must be called BEFORE the Jac LSP starts (i.e. before a .jac file is opened,
---or before `require("jac.lsp").start()` is called manually).
---
---@param opts? table Optional overrides:
---   - capabilities: A custom capabilities table (defaults to cmp_nvim_lsp.default_capabilities())
function M.setup(opts)
  opts = opts or {}

  local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if not ok then
    vim.notify(
      "[jac.nvim] cmp_nvim_lsp not found. Install hrsh7th/cmp-nvim-lsp to use nvim-cmp with Jac.",
      vim.log.levels.WARN
    )
    return
  end

  local jac = require("jac")

  -- Build capabilities: user-provided > cmp_nvim_lsp defaults > existing config
  local caps = opts.capabilities or cmp_nvim_lsp.default_capabilities()
  jac.config.capabilities = vim.tbl_deep_extend("keep", jac.config.capabilities or {}, caps)
end

return M

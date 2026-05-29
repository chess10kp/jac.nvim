---@module "jac.blink"
---Integration with blink.cmp (saghen/blink.cmp) for Jac LSP completions.
---
---Usage:
---```lua
---require("jac.blink").setup()
---```
---
---This auto-detects blink.cmp, retrieves its required LSP client capabilities
---via `blink.cmp.get_lsp_capabilities()`, and merges them into jac.config so
---the Jac LSP server can provide completions through blink.cmp.

local M = {}

---Wire up blink.cmp LSP capabilities for the Jac language server.
---
---Must be called BEFORE the Jac LSP starts (i.e. before a .jac file is opened,
---or before `require("jac.lsp").start()` is called manually).
---
---@param opts? table Optional overrides:
---   - capabilities: A custom capabilities table (defaults to blink.cmp.get_lsp_capabilities())
function M.setup(opts)
  opts = opts or {}

  local ok, blink = pcall(require, "blink.cmp")
  if not ok then
    vim.notify(
      "[jac.nvim] blink.cmp not found. Install saghen/blink.cmp to use blink.cmp with Jac.",
      vim.log.levels.WARN
    )
    return
  end

  local jac = require("jac")

  -- Build capabilities: user-provided > blink.cmp defaults > existing config
  local caps = opts.capabilities or blink.get_lsp_capabilities()
  jac.config.capabilities = vim.tbl_deep_extend("keep", jac.config.capabilities or {}, caps)
end

return M

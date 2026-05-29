---@module "jac.coq"
---Integration with coq_nvim (ms-jpq/coq_nvim) for Jac LSP completions.
---
---Usage:
---```lua
---require("jac.coq").setup()
---```
---
---This auto-detects coq_nvim and configures the Jac LSP server with
---`coq.lsp_ensure_capabilities()`, which merges coq's required LSP client
---capabilities so the Jac LSP can provide completions and snippets
---through coq_nvim.
---
---Unlike nvim-cmp and blink.cmp, coq_nvim wraps the entire server setup
---table rather than just providing a capabilities object. This module
---sets an internal flag (`jac.config.coq`) that jac.lsp checks when
---starting the language server.

local M = {}

---Enable coq_nvim LSP integration for the Jac language server.
---
---Must be called BEFORE the Jac LSP starts (i.e. before a .jac file is opened,
---or before `require("jac.lsp").start()` is called manually).
---
function M.setup()
  local ok, _ = pcall(require, "coq")
  if not ok then
    vim.notify(
      "[jac.nvim] coq_nvim not found. Install ms-jpq/coq_nvim to use coq with Jac.",
      vim.log.levels.WARN
    )
    return
  end

  local jac = require("jac")
  jac.config.coq = true
end

return M

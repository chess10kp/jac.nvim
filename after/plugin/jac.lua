-- after/plugin/jac.lua
-- Heavy loading for jac.nvim - runs after Neovim is fully initialized
-- This ensures LSP and treesitter are loaded at the right time

-- Setup jac.nvim with user configuration
local jac = require("jac")
if not jac._initialized then
  jac.setup({
    auto_start = true,
    blink = true,
    treesitter = true,
  })
end

-- Auto-start LSP for any existing jac buffers
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.bo[buf].filetype == "jac" then
    vim.api.nvim_buf_call(buf, function()
      require("jac.lsp").auto_start()
    end)
  end
end

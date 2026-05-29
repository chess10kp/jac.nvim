-- plugin/jac.lua
-- Auto-loaded entry point for jac.nvim.
-- Ensures filetype detection and LSP auto-start are set up on Neovim startup.

local function ensure_setup()
  if not require("jac")._initialized then
    require("jac").setup()
  end
end

-- Handle both eager-loaded and lazy-loaded scenarios:
-- If VimEnter has already fired (lazy-load), run setup now.
-- Otherwise (startup), defer until VimEnter.
if vim.v.vim_did_enter == 1 then
  ensure_setup()
else
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = ensure_setup,
  })
end

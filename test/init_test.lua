-- test/init_test.lua
-- Minimal Neovim config to test jac.nvim plugin

-- Add the project root to runtimepath so nvim finds the plugin
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Basic config to allow testing
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")

-- Now require and setup jac.nvim
require("jac").setup({
  auto_start = true,
})

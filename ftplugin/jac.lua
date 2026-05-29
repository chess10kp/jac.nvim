-- ftplugin/jac.lua
-- Filetype-specific settings for Jac programming language

-- Jac uses curly braces {} and semicolons, like C/JS/Java
vim.bo.commentstring = "# %s"
vim.bo.comments = ":#"

-- Indentation: 4 spaces (standard for Jac)
vim.bo.tabstop = 4
vim.bo.softtabstop = 4
vim.bo.shiftwidth = 4
vim.bo.expandtab = true

-- Jac is curly-brace based, so these help with auto-indent
vim.bo.cindent = false
vim.bo.smartindent = true
vim.bo.autoindent = true

-- Formatting options
vim.bo.formatoptions = vim.bo.formatoptions:gsub("o", "")

-- Wrap long lines
vim.wo.wrap = false

-- Folding (based on braces)
vim.wo.foldmethod = "manual"

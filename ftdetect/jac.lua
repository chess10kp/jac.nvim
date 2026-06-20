-- Filetype detection for Jac.
-- A single `extension` rule covers `*.jac` and every flavored variant
-- (`*.impl.jac`, `*.cl.jac`, `*.sv.jac`, `*.na.jac`, `*.test.jac`) because
-- Neovim keys on the final extension, which is always `jac`.

vim.filetype.add({
  extension = { jac = "jac" },
})

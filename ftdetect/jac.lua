-- Filetype detection for Jac programming language
-- Detects all Jac file extensions: .jac, .sv.jac, .cl.jac, .na.jac, .impl.jac, .test.jac

vim.filetype.add({
  extension = {
    jac = "jac",
  },
  pattern = {
    ["%.sv%.jac$"] = "jac",
    ["%.cl%.jac$"] = "jac",
    ["%.na%.jac$"] = "jac",
    ["%.impl%.jac$"] = "jac",
    ["%.test%.jac$"] = "jac",
  },
})

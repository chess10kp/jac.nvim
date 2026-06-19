# jac.nvim

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lua](https://img.shields.io/badge/Lua-5.1-blue.svg)](https://www.lua.org)

Neovim plugin for the [Jac](https://docs.jaseci.org) programming language by [Jaseci Labs](https://jaseci.org).

Automatically detects `.jac` files, starts the Jac language server, and enables Tree-sitter highlighting.

## Features

- 🔍 **Filetype detection** for all Jac extensions: `.jac`, `.sv.jac`, `.cl.jac`, `.na.jac`, `.impl.jac`, `.test.jac`
- 🚀 **Auto-start LSP** — no manual configuration needed
- 🌳 **Tree-sitter integration** — syntax highlighting, code folding, and text objects
- ⚙️ **Customizable** — pass `on_attach`, `capabilities`, and other LSP options

## Requirements

- Neovim ≥ 0.8.0
- [jaclang](https://pypi.org/project/jaclang/) installed and available in PATH:
  ```bash
  pip install jaclang
  ```
- `curl`, `tar`, and a C compiler (cc, gcc, or clang) if using `auto_install`

## Installation

```bash
pip install jaclang
```

### lazy.nvim

```lua
{
  "chess10kp/jac.nvim",
  ft = "jac",
  dependencies = {
    "neovim/nvim-lspconfig", -- optional
  },
  config = function()
    require("jac").setup({
      treesitter = { auto_install = true }, -- auto-install parser
    })
  end,
}
```

### packer.nvim

```lua
use {
  "chess10kp/jac.nvim",
  requires = { "neovim/nvim-lspconfig" },
  config = function()
    require("jac").setup()
  end,
}
```

### vim-plug

```vim
Plug 'neovim/nvim-lspconfig'
Plug 'chess10kp/jac.nvim'

lua << EOF
require("jac").setup()
EOF
```

## Usage

```lua
require("jac").setup()
```

This provides:
- Automatic LSP startup for `.jac` files
- Tree-sitter highlighting (when parser is installed)

### Manual parser installation

```vim
:lua require("jac.treesitter").install()
```

## Configuration

<details>
<summary>Advanced configuration</summary>

```lua
require("jac").setup({
  -- Automatically start the LSP when opening a .jac file (default: true)
  auto_start = true,

  -- Pass LSP client capabilities (e.g. from nvim-cmp)
  capabilities = capabilities,

  -- Custom on_attach function for keymaps, etc.
  on_attach = function(client, bufnr)
    -- Your custom keymaps here
  end,

  -- LSP server settings
  settings = {},

  -- Tree-sitter integration (default: true)
  treesitter = true,
})
```

</details>

## Completion Plugin Integration

<details>
<summary>nvim-cmp</summary>

```lua
require("jac").setup({
  cmp = true,  -- auto-detects cmp_nvim_lsp and wires up capabilities
})
```

Or manually:
```lua
local capabilities = require("cmp_nvim_lsp").default_capabilities()
require("jac").setup({ capabilities = capabilities })
```

</details>

<details>
<summary>blink.cmp</summary>

```lua
require("jac").setup({
  blink = true,  -- auto-detects blink.cmp and wires up capabilities
})
```

Or manually:
```lua
local capabilities = require("blink.cmp").get_lsp_capabilities()
require("jac").setup({ capabilities = capabilities })
```

</details>

<details>
<summary>coq_nvim</summary>

```lua
require("jac").setup({
  coq = true,  -- wraps LSP setup with coq.lsp_ensure_capabilities()
})
```

</details>

## Tree-sitter Features

The Jac parser provides:
- **Syntax highlighting** — including f-string interpolations & JSX
- **Code folding** — `foldmethod=expr` folding
- **Local variables** — scopes & definitions
- **Language injections** — embedded Python in `::py::` blocks

### Folding setup

```lua
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
```

### Note on embedded languages

For embedded Python highlighting, ensure you have the Python Tree-sitter parser installed:

```vim
:TSInstall python
```

## License

MIT

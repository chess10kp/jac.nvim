# jac.nvim

Neovim plugin for the [Jac](https://docs.jaseci.org) programming language by [Jaseci Labs](https://jaseci.org).

Automatically detects `.jac` files and starts the built-in Jac language server for LSP support (completions, diagnostics, hover, go-to-definition, etc.).

## Features

- 🔍 **Filetype detection** for all Jac extensions: `.jac`, `.sv.jac`, `.cl.jac`, `.na.jac`, `.impl.jac`, `.test.jac`
- 🚀 **Auto-start LSP** — no manual configuration needed
- ⚙️ **Customizable** — pass `on_attach`, `capabilities`, and other LSP options

## Requirements

- Neovim ≥ 0.8.0
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [jaclang](https://pypi.org/project/jaclang/) installed and available in PATH:
  ```bash
  pip install jaclang
  ```

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/jac.nvim",
  dependencies = { "neovim/nvim-lspconfig" },
  config = function()
    require("jac").setup({
      -- optional: override defaults
      -- auto_start = true,        -- auto-start LSP (default: true)
      -- on_attach = my_on_attach, -- custom LSP on_attach
      -- capabilities = my_caps,   -- from nvim-cmp
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/jac.nvim",
  requires = { "neovim/nvim-lspconfig" },
  config = function()
    require("jac").setup()
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'neovim/nvim-lspconfig'
Plug 'your-username/jac.nvim'

lua << EOF
require("jac").setup()
EOF
```

## Completion Plugin Integration

### nvim-cmp

**Option A — One-liner in setup:**

```lua
require("jac").setup({
  cmp = true,  -- auto-detects cmp_nvim_lsp and wires up capabilities
})
```

**Option B — Standalone module:**

```lua
require("jac").setup()
require("jac.cmp").setup()
```

**Option C — Manual capabilities:**

```lua
local capabilities = require("cmp_nvim_lsp").default_capabilities()
require("jac").setup({ capabilities = capabilities })
```

### blink.cmp

**Option A — One-liner in setup:**

```lua
require("jac").setup({
  blink = true,  -- auto-detects blink.cmp and wires up capabilities
})
```

**Option B — Standalone module:**

```lua
require("jac").setup()
require("jac.blink").setup()
```

**Option C — Manual capabilities:**

```lua
local capabilities = require("blink.cmp").get_lsp_capabilities()
require("jac").setup({ capabilities = capabilities })
```

### Advanced: Custom capabilities

To merge custom capabilities on top of completion defaults:

```lua
-- nvim-cmp
require("jac").setup({
  cmp = { capabilities = my_custom_capabilities },
})

-- blink.cmp
require("jac").setup({
  blink = { capabilities = my_custom_capabilities },
})
```

### coq_nvim

**Option A — One-liner in setup:**

```lua
require("jac").setup({
  coq = true,  -- wraps LSP setup with coq.lsp_ensure_capabilities()
})
```

**Option B — Standalone module:**

```lua
require("jac").setup()
require("jac.coq").setup()
```

**Note:** coq_nvim uses `coq.lsp_ensure_capabilities()` which wraps the entire LSP server setup table (not just capabilities). jac.nvim handles this automatically when `coq = true` or `jac.coq.setup()` is called.

## Configuration

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

  -- LSP client flags
  flags = {},

  -- nvim-cmp integration (default: false)
  cmp = true,

  -- blink.cmp integration (default: false)
  blink = true,

  -- coq_nvim integration (default: false)
  coq = true,
})
```

## Plugin Structure

```
jac.nvim/
├── ftdetect/jac.lua       # Filetype detection (.jac, .sv.jac, etc.)
├── ftplugin/jac.lua       # Filetype-specific settings (indent, comments)
├── syntax/jac.vim          # Syntax highlighting (Vim regex)
├── lua/jac/init.lua       # Main setup() with user config
├── lua/jac/lsp.lua        # LSP registration and auto-start
├── lua/jac/cmp.lua        # nvim-cmp integration
├── lua/jac/blink.lua      # blink.cmp integration
├── lua/jac/coq.lua        # coq_nvim integration
├── plugin/jac.lua         # Auto-load entry point
├── test/sample.jac        # Sample Jac file for testing
└── test/init_test.lua     # Minimal test config
```

## How It Works

1. `ftdetect/jac.lua` registers all Jac file extensions as `jac` filetype
2. When a `.jac` file is opened, an autocmd fires
3. `lua/jac/lsp.lua` registers `jac_ls` with `nvim-lspconfig` and starts the server via `jac lsp`
4. Completion plugins (nvim-cmp / blink.cmp / coq_nvim) are auto-configured if `cmp = true`, `blink = true`, or `coq = true`
5. The LSP server handles completions, diagnostics, hover, go-to-definition, references, etc.

## Manual LSP Start

If you disable `auto_start`, you can start the LSP manually:

```vim
:lua require("jac.lsp").start()
```

## License

MIT

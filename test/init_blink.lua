-- test/init_blink.lua
-- Minimal test config for blink.cmp + jac.nvim integration
--
-- Requires blink.cmp to be installed alongside jac.nvim.
-- Run: nvim --headless -u test/init_blink.lua test/sample.jac -c "lua test_assertions()" -c "qa!"

-- Set up package path to include local test deps and the plugin itself
local plugin_root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
vim.opt.rtp:prepend(plugin_root)

-- Bootstrap: try to load blink.cmp, warn if missing
local has_blink, blink = pcall(require, "blink.cmp")
local has_lspconfig, _ = pcall(require, "lspconfig")

if not has_blink then
  vim.notify("[test] blink.cmp not found — completions won't be tested", vim.log.levels.WARN)
end
if not has_lspconfig then
  vim.notify("[test] nvim-lspconfig not found — jac.nvim will fall back to vim.lsp.start", vim.log.levels.WARN)
end

-- Configure blink.cmp (only if available)
if has_blink then
  blink.setup({
    sources = {
      default = { "lsp" },
    },
  })
end

-- Setup jac.nvim with blink.cmp integration
require("jac").setup({
  blink = true,
  auto_start = false, -- we'll trigger manually for testing
})

-- Test assertions
function _G.test_assertions()
  local jac = require("jac")
  local results = {}

  -- 1. Config should have blink enabled when blink.cmp is available
  if has_blink then
    if jac.config.blink then
      table.insert(results, "PASS: jac.config.blink is true")
    else
      table.insert(results, "FAIL: jac.config.blink should be true when blink.cmp is present")
    end
  else
    if jac.config.blink == false then
      table.insert(results, "PASS: jac.config.blink fell back to false (blink.cmp not available)")
    else
      table.insert(results, "FAIL: jac.config.blink should be false when blink.cmp is missing")
    end
  end

  -- 2. Config should NOT have spurious cmp/coq enabled
  if jac.config.cmp ~= false then
    table.insert(results, "FAIL: jac.config.cmp should be false, got " .. tostring(jac.config.cmp))
  else
    table.insert(results, "PASS: jac.config.cmp stayed false")
  end
  if jac.config.coq ~= false then
    table.insert(results, "FAIL: jac.config.coq should be false, got " .. tostring(jac.config.coq))
  else
    table.insert(results, "PASS: jac.config.coq stayed false")
  end

  -- 3. capabilities should be set when blink.cmp is available
  if has_blink then
    if jac.config.capabilities then
      table.insert(results, "PASS: jac.config.capabilities is set")
    else
      table.insert(results, "FAIL: jac.config.capabilities should be set when blink.cmp is present")
    end
  else
    table.insert(results, "SKIP: blink.cmp not available")
  end

  -- 4. Try to start LSP and check for errors
  local ok, err = pcall(require("jac.lsp").start)
  if ok then
    table.insert(results, "PASS: jac.lsp.start() succeeded")
  else
    table.insert(results, "FAIL: jac.lsp.start() error: " .. tostring(err))
  end

  print("\n=== Test Results (blink.cmp) ===")
  for _, r in ipairs(results) do
    print(r)
  end
  print("==================================\n")
end

-- test/init_coq.lua
-- Minimal test config for coq_nvim + jac.nvim integration
--
-- Requires coq_nvim to be installed alongside jac.nvim.
-- Run: nvim --headless -u test/init_coq.lua test/sample.jac -c "lua test_assertions()" -c "qa!"

-- Set up package path to include local test deps and the plugin itself
local plugin_root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
vim.opt.rtp:prepend(plugin_root)

-- Bootstrap: try to load coq_nvim, warn if missing
local has_coq, _ = pcall(require, "coq")
local has_lspconfig, _ = pcall(require, "lspconfig")

if not has_coq then
  vim.notify("[test] coq_nvim not found — completions won't be tested", vim.log.levels.WARN)
end
if not has_lspconfig then
  vim.notify("[test] nvim-lspconfig not found — LSP won't work", vim.log.levels.ERROR)
end

-- Setup jac.nvim with coq_nvim integration
require("jac").setup({
  coq = true,
  auto_start = false, -- we'll trigger manually for testing
})

-- Test assertions
function _G.test_assertions()
  local jac = require("jac")
  local results = {}

  -- 1. Config should have coq enabled when coq_nvim is available
  if has_coq then
    if jac.config.coq then
      table.insert(results, "PASS: jac.config.coq is true")
    else
      table.insert(results, "FAIL: jac.config.coq should be true when coq_nvim is present")
    end
  else
    if jac.config.coq == false then
      table.insert(results, "PASS: jac.config.coq fell back to false (coq_nvim not available)")
    else
      table.insert(results, "FAIL: jac.config.coq should be false when coq_nvim is missing")
    end
  end

  -- 2. Config should NOT have spurious cmp/blink enabled
  if jac.config.cmp ~= false then
    table.insert(results, "FAIL: jac.config.cmp should be false, got " .. tostring(jac.config.cmp))
  else
    table.insert(results, "PASS: jac.config.cmp stayed false")
  end
  if jac.config.blink ~= false then
    table.insert(results, "FAIL: jac.config.blink should be false, got " .. tostring(jac.config.blink))
  else
    table.insert(results, "PASS: jac.config.blink stayed false")
  end

  -- 3. Try to start LSP and check for errors
  local ok, err = pcall(require("jac.lsp").start)
  if ok then
    table.insert(results, "PASS: jac.lsp.start() succeeded")
  else
    table.insert(results, "FAIL: jac.lsp.start() error: " .. tostring(err))
  end

  print("\n=== Test Results (coq_nvim) ===")
  for _, r in ipairs(results) do
    print(r)
  end
  print("===============================\n")
end

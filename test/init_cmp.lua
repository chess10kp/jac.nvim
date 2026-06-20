-- test/init_cmp.lua
-- Minimal test config for nvim-cmp + jac.nvim integration
--
-- Requires nvim-cmp and cmp-nvim-lsp to be installed alongside jac.nvim.
-- Run: nvim --headless -u test/init_cmp.lua test/sample.jac -c "lua test_assertions()" -c "qa!"

-- Set up package path to include local test deps and the plugin itself
local plugin_root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
vim.opt.rtp:prepend(plugin_root)

-- Bootstrap: try to load completion dependencies, warn if missing
local has_cmp, cmp = pcall(require, "cmp")
local has_cmp_lsp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
local has_lspconfig, _ = pcall(require, "lspconfig")

if not has_cmp then
  vim.notify("[test] nvim-cmp not found — completions won't be tested", vim.log.levels.WARN)
end
if not has_cmp_lsp then
  vim.notify("[test] cmp-nvim-lsp not found — LSP completions won't be tested", vim.log.levels.WARN)
end
if not has_lspconfig then
  vim.notify("[test] nvim-lspconfig not found — jac.nvim will fall back to vim.lsp.start", vim.log.levels.WARN)
end

-- Configure nvim-cmp (only if available)
if has_cmp and has_cmp_lsp then
  cmp.setup({
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
    }),
  })
end

-- Setup jac.nvim with nvim-cmp integration
require("jac").setup({
  cmp = true,
  auto_start = false, -- we'll trigger manually for testing
})

-- Test assertions
function _G.test_assertions()
  local jac = require("jac")
  local results = {}

  -- 1. Config should have cmp enabled when cmp_nvim_lsp is available
  if has_cmp_lsp then
    if jac.config.cmp then
      table.insert(results, "PASS: jac.config.cmp is true")
    else
      table.insert(results, "FAIL: jac.config.cmp should be true when cmp_nvim_lsp is present")
    end
  else
    if jac.config.cmp == false then
      table.insert(results, "PASS: jac.config.cmp fell back to false (cmp_nvim_lsp not available)")
    else
      table.insert(results, "FAIL: jac.config.cmp should be false when cmp_nvim_lsp is missing")
    end
  end

  -- 2. Config should NOT have spurious blink/coq enabled
  if jac.config.blink ~= false then
    table.insert(results, "FAIL: jac.config.blink should be false, got " .. tostring(jac.config.blink))
  else
    table.insert(results, "PASS: jac.config.blink stayed false")
  end
  if jac.config.coq ~= false then
    table.insert(results, "FAIL: jac.config.coq should be false, got " .. tostring(jac.config.coq))
  else
    table.insert(results, "PASS: jac.config.coq stayed false")
  end

  -- 3. capabilities should be set when cmp_nvim_lsp is available
  if has_cmp_lsp then
    if jac.config.capabilities then
      table.insert(results, "PASS: jac.config.capabilities is set")
    else
      table.insert(results, "FAIL: jac.config.capabilities should be set when cmp_nvim_lsp is present")
    end
  else
    table.insert(results, "SKIP: cmp_nvim_lsp not available")
  end

  -- 4. Try to start LSP and check for errors
  local ok, err = pcall(require("jac.lsp").start)
  if ok then
    table.insert(results, "PASS: jac.lsp.start() succeeded")
  else
    table.insert(results, "FAIL: jac.lsp.start() error: " .. tostring(err))
  end

  print("\n=== Test Results (nvim-cmp) ===")
  for _, r in ipairs(results) do
    print(r)
  end
  print("===============================\n")
end

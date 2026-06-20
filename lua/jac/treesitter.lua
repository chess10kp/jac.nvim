---@module "jac.treesitter"
---Core Tree-sitter integration for Jac syntax highlighting and parser management.
---
---Usage:
---```lua
---require("jac").setup({
---  treesitter = true,  -- enable Tree-sitter integration (default)
---})
---```
---
---Or standalone:
---```lua
---require("jac.treesitter").setup()
---```
---
---This module uses Neovim's built-in Tree-sitter APIs directly. If the Jac parser
---is installed, jac.nvim will start Tree-sitter highlighting automatically for
---Jac buffers. If `auto_install = true`, jac.nvim downloads the latest
---tree-sitter-jac release, compiles the parser locally, and syncs its queries.

local uv = vim.uv or vim.loop
local M = {}

local RELEASE_API_URL = "https://api.github.com/repos/jaseci-labs/tree-sitter-jac/releases/latest"
local INSTALL_ROOT_NAME = "jac.nvim"
local PATH_SEP = package.config:sub(1, 1)

---Default configuration
---@class jac.TreesitterConfig
---@field auto_install boolean Automatically install the parser if not present (default: false)
---@field enable boolean Enable treesitter integration (default: true)

M.config = {
  auto_install = false,
  enable = true,
}

local function joinpath(...)
  return table.concat({ ... }, PATH_SEP)
end

local function install_root()
  return joinpath(vim.fn.stdpath("data"), INSTALL_ROOT_NAME)
end

local function parser_dir()
  return joinpath(install_root(), "parser")
end

local function query_dir()
  return joinpath(install_root(), "queries", "jac")
end

local function parser_path()
  return joinpath(parser_dir(), "jac.so")
end

local function release_file()
  return joinpath(install_root(), "parser-info", "jac.release")
end

local function path_exists(path)
  return uv.fs_stat(path) ~= nil
end

local function notify(msg, level)
  vim.notify(msg, level, { title = "jac.nvim" })
end

local function core_treesitter_available()
  return vim.treesitter
    and vim.treesitter.language
    and type(vim.treesitter.language.add) == "function"
end

local function highlight_available()
  return vim.treesitter and type(vim.treesitter.start) == "function"
end

local function runtimepath_contains(path)
  return ("," .. vim.o.runtimepath .. ","):find("," .. path .. ",", 1, true) ~= nil
end

local function ensure_runtimepath()
  local root = install_root()
  if not runtimepath_contains(root) then
    vim.opt.runtimepath:append(root)
  end
end

local function mkdir_p(path)
  vim.fn.mkdir(path, "p")
end

local function decode_json(data)
  if vim.json and vim.json.decode then
    return vim.json.decode(data)
  end
  return vim.fn.json_decode(data)
end

local function run_command(cmd, opts)
  opts = opts or {}

  if vim.system then
    local result = vim.system(cmd, {
      cwd = opts.cwd,
      text = true,
    }):wait()
    return result.code == 0, result.stdout or "", result.stderr or ""
  end

  local parts = {}
  if opts.cwd then
    parts[#parts + 1] = "cd " .. vim.fn.shellescape(opts.cwd)
    parts[#parts + 1] = "&&"
  end
  for _, arg in ipairs(cmd) do
    parts[#parts + 1] = vim.fn.shellescape(arg)
  end

  local output = vim.fn.system(table.concat(parts, " "))
  local ok = vim.v.shell_error == 0
  return ok, output, ok and "" or output
end

local function command_error(stdout, stderr)
  local err = stderr ~= "" and stderr or stdout
  return vim.trim(err)
end

local function installed_release()
  if not path_exists(release_file()) then
    return nil
  end
  local lines = vim.fn.readfile(release_file())
  return lines[1]
end

local function write_release(tag)
  mkdir_p(vim.fn.fnamemodify(release_file(), ":h"))
  vim.fn.writefile({ tag }, release_file())
end

local function has_installed_parser()
  return path_exists(parser_path())
end

local function parser_available()
  if not core_treesitter_available() then
    return false
  end

  if has_installed_parser() then
    local ok = pcall(vim.treesitter.language.add, "jac", { path = parser_path() })
    return ok
  end

  local ok = pcall(vim.treesitter.language.add, "jac")
  return ok
end

local function load_parser()
  ensure_runtimepath()

  if has_installed_parser() then
    return pcall(vim.treesitter.language.add, "jac", { path = parser_path() })
  end

  return pcall(vim.treesitter.language.add, "jac")
end

local function copy_file(src, dest)
  local input = assert(io.open(src, "rb"))
  local content = input:read("*a")
  input:close()

  mkdir_p(vim.fn.fnamemodify(dest, ":h"))
  local output = assert(io.open(dest, "wb"))
  output:write(content)
  output:close()
end

local function sync_queries(src_dir, dest_dir)
  mkdir_p(dest_dir)

  for _, existing in ipairs(vim.fn.glob(joinpath(dest_dir, "*.scm"), false, true)) do
    vim.fn.delete(existing)
  end

  for _, src in ipairs(vim.fn.glob(joinpath(src_dir, "*.scm"), false, true)) do
    local dest = joinpath(dest_dir, vim.fn.fnamemodify(src, ":t"))
    copy_file(src, dest)
  end
end

local function release_info()
  local ok, stdout, stderr = run_command({ "curl", "-fsSL", RELEASE_API_URL })
  if not ok then
    return nil, nil, "Failed to fetch release metadata: " .. command_error(stdout, stderr)
  end

  local decoded_ok, data = pcall(decode_json, stdout)
  if not decoded_ok or type(data) ~= "table" then
    return nil, nil, "Failed to parse release metadata from GitHub."
  end

  if type(data.tarball_url) ~= "string" or data.tarball_url == "" then
    return nil, nil, "Latest release metadata did not include a tarball URL."
  end

  return data.tag_name or data.name or "latest", data.tarball_url
end

local function compiler_command(source_root, output_path)
  if PATH_SEP == "\\" then
    return nil, "Automatic Jac parser installation is not yet supported on Windows."
  end

  local compiler
  for _, candidate in ipairs({ "cc", "gcc", "clang" }) do
    if vim.fn.executable(candidate) == 1 then
      compiler = candidate
      break
    end
  end

  if not compiler then
    return nil, "No C compiler found in PATH. Install cc, gcc, or clang."
  end

  local src_dir = joinpath(source_root, "src")
  return {
    compiler,
    "-O2",
    "-std=c11",
    "-fPIC",
    "-I",
    src_dir,
    "-shared",
    joinpath(src_dir, "parser.c"),
    joinpath(src_dir, "scanner.c"),
    "-o",
    output_path,
  }
end

local function extracted_release_root(tmpdir)
  for _, path in ipairs(vim.fn.glob(joinpath(tmpdir, "*"), false, true)) do
    local stat = uv.fs_stat(path)
    if stat and stat.type == "directory" then
      return path
    end
  end
  return nil
end

local function enable_buffer(bufnr)
  if not highlight_available() or vim.bo[bufnr].filetype ~= "jac" then
    return
  end

  if not load_parser() then
    return
  end

  pcall(vim.treesitter.start, bufnr, "jac")
end

local function refresh_open_buffers()
  if not highlight_available() then
    return
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      enable_buffer(bufnr)
    end
  end
end

---Install the Jac Tree-sitter parser from the latest GitHub release.
---@return boolean success
local function install_parser()
  if not core_treesitter_available() then
    notify(
      "[jac.nvim] Neovim's built-in Tree-sitter APIs are unavailable in this version.",
      vim.log.levels.ERROR
    )
    return false
  end

  for _, executable in ipairs({ "curl", "tar" }) do
    if vim.fn.executable(executable) ~= 1 then
      notify(
        string.format("[jac.nvim] `%s` is required to install the Jac parser.", executable),
        vim.log.levels.ERROR
      )
      return false
    end
  end

  local release_tag, tarball_url, release_err = release_info()
  if not release_tag then
    notify("[jac.nvim] " .. release_err, vim.log.levels.ERROR)
    return false
  end

  local tmpdir = vim.fn.tempname()
  mkdir_p(tmpdir)

  local tarball_path = joinpath(tmpdir, "tree-sitter-jac.tar.gz")
  local parser_output = joinpath(tmpdir, "jac.so")
  local ok, stdout, stderr

  notify(
    string.format("[jac.nvim] Installing Jac Tree-sitter parser from %s...", release_tag),
    vim.log.levels.INFO
  )

  ok, stdout, stderr = run_command({ "curl", "-fsSL", "-o", tarball_path, tarball_url })
  if not ok then
    vim.fn.delete(tmpdir, "rf")
    notify("[jac.nvim] Failed to download parser release: " .. command_error(stdout, stderr), vim.log.levels.ERROR)
    return false
  end

  ok, stdout, stderr = run_command({ "tar", "-xzf", tarball_path, "-C", tmpdir })
  if not ok then
    vim.fn.delete(tmpdir, "rf")
    notify("[jac.nvim] Failed to extract parser release: " .. command_error(stdout, stderr), vim.log.levels.ERROR)
    return false
  end

  local source_root = extracted_release_root(tmpdir)
  if not source_root then
    vim.fn.delete(tmpdir, "rf")
    notify("[jac.nvim] Failed to locate extracted parser sources.", vim.log.levels.ERROR)
    return false
  end

  local compile_cmd, compile_err = compiler_command(source_root, parser_output)
  if not compile_cmd then
    vim.fn.delete(tmpdir, "rf")
    notify("[jac.nvim] " .. compile_err, vim.log.levels.ERROR)
    return false
  end

  ok, stdout, stderr = run_command(compile_cmd)
  if not ok then
    vim.fn.delete(tmpdir, "rf")
    notify("[jac.nvim] Failed to compile Jac parser: " .. command_error(stdout, stderr), vim.log.levels.ERROR)
    return false
  end

  copy_file(parser_output, parser_path())
  sync_queries(joinpath(source_root, "queries", "jac"), query_dir())
  write_release(release_tag)
  ensure_runtimepath()

  local loaded = load_parser()
  vim.fn.delete(tmpdir, "rf")

  if not loaded then
    notify("[jac.nvim] Installed the parser files, but Neovim failed to load the Jac parser.", vim.log.levels.ERROR)
    return false
  end

  refresh_open_buffers()
  notify(
    string.format("[jac.nvim] Installed Jac Tree-sitter parser %s.", release_tag),
    vim.log.levels.INFO
  )
  return true
end

---Setup Jac Tree-sitter integration.
---@param opts? jac.TreesitterConfig
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("keep", opts, M.config)

  if not M.config.enable then
    return
  end

  if not core_treesitter_available() then
    return
  end

  ensure_runtimepath()

  local group = vim.api.nvim_create_augroup("JacNvimTreesitter", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "jac",
    callback = function(args)
      enable_buffer(args.buf)
    end,
    desc = "Start Jac Tree-sitter highlighting",
  })

  if M.config.auto_install and not parser_available() then
    install_parser()
  else
    refresh_open_buffers()
  end
end

---Manually install the Jac parser.
function M.install()
  return install_parser()
end

---Return the installed release tag, if jac.nvim installed the parser itself.
---@return string|nil
function M.installed_release()
  return installed_release()
end

return M

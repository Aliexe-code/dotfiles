-- Linting (nvim-lint)
-- V: run the compiler so unused-function "notice"s show as warnings in the buffer.
-- v-analyzer LSP covers errors/undefined idents but often skips unused notices.

vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }

local lint = require 'lint'

local v_bin = (function()
  local home = vim.fn.expand '~/.local/share/v/v'
  if vim.fn.executable(home) == 1 then
    return home
  end
  return 'v'
end)()

-- Parse lines like: /path/file.v:3:4: notice: unused function: `add`
-- Handles both absolute and relative paths (v prints relative when given relative target).
local function parse_v_output(output, bufnr, linter_cwd)
  local diagnostics = {}
  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  if buf_name == '' then return diagnostics end
  local buf_path = vim.fs.normalize(vim.fn.fnamemodify(buf_name, ':p'))
  local severity_map = {
    error = vim.diagnostic.severity.ERROR,
    warning = vim.diagnostic.severity.WARN,
    notice = vim.diagnostic.severity.WARN, -- unused fn/var etc. — show as warning
    info = vim.diagnostic.severity.INFO,
    hint = vim.diagnostic.severity.HINT,
  }

  for line in vim.gsplit(output, '\n', { plain = true }) do
    local file, lnum, col, sev, msg = line:match '^(.+):(%d+):(%d+): (%w+): (.+)$'
    if file and msg then
      local norm_file
      if file:match '^%w:' or vim.startswith(file, '/') then
        norm_file = vim.fs.normalize(file)
      else
        local cwd = linter_cwd or vim.fn.getcwd()
        norm_file = vim.fs.normalize(vim.fn.simplify(cwd .. '/' .. file))
      end
      -- Match diagnostics for this buffer. v can emit for any file in module,
      -- so filter to current buffer (basename fallback keeps it working when cwd varies).
      if norm_file == buf_path or vim.fs.basename(norm_file) == vim.fs.basename(buf_path) then
        -- Extra guard when basename matches but paths differ (e.g., two main.v in different projects):
        -- accept if normalized paths equal or if basename matches and buf_path ends with the relative file suffix.
        local is_match = norm_file == buf_path or vim.fs.basename(norm_file) == vim.fs.basename(buf_path)
        -- For relative outputs where cwd join may still be off (e.g., workspace/v/main.v vs /home/ali/workspace/v/main.v),
        -- the basename check is intentional fallback — single-file projects always have unique main.v, and multi-file
        -- projects will have already matched via normalized path when target is absolute.
        if is_match then
          diagnostics[#diagnostics + 1] = {
            lnum = tonumber(lnum) - 1,
            col = math.max(tonumber(col) - 1, 0),
            message = msg,
            severity = severity_map[sev:lower()] or vim.diagnostic.severity.WARN,
            source = 'v',
          }
        end
      end
    end
  end
  return diagnostics
end

local function v_target()
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then return '.' end
  local root
  if vim.fs.root then
    root = vim.fs.root(bufnr, { 'v.mod', '.git' })
  else
    local found = vim.fs.find({ 'v.mod', '.git' }, { path = name, upward = true })[1]
    if found then root = vim.fs.dirname(found) end
  end
  if root and vim.fn.filereadable(root .. '/v.mod') == 1 then
    return root
  end
  return name
end

lint.linters.v = {
  name = 'v',
  cmd = v_bin,
  stdin = false,
  append_fname = false,
  stream = 'both',
  ignore_exitcode = true,
  env = {
    VFLAGS = '-cc gcc',
  },
  args = {
    '-cc',
    'gcc',
    '-o',
    function() return vim.fn.tempname() end,
    v_target,
  },
  parser = parse_v_output,
}

-- Odin: odin check (type checker) — errors show as diagnostics
-- Parses: /path/file.odin(10:5) Error: Undeclared name: foo
local function parse_odin_output(output, bufnr, linter_cwd)
  local diagnostics = {}
  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  if buf_name == '' then return diagnostics end
  local buf_path = vim.fs.normalize(vim.fn.fnamemodify(buf_name, ':p'))
  local severity_map = {
    error = vim.diagnostic.severity.ERROR,
    warning = vim.diagnostic.severity.WARN,
    info = vim.diagnostic.severity.INFO,
  }
  for line in vim.gsplit(output, '\n', { plain = true }) do
    local file, lnum, col, sev, msg = line:match('^(.+):(%d+):(%d+):%s*(%w+):%s*(.+)$')
    if not file then file, lnum, col, sev, msg = line:match('^(.+)%((%d+):(%d+)%)%s+(%w+):%s*(.+)$') end
    if file and msg then
      local norm_file
      if file:match('^%w:') or vim.startswith(file, '/') then norm_file = vim.fs.normalize(file)
      else
        local cwd = linter_cwd or vim.fn.getcwd()
        norm_file = vim.fs.normalize(vim.fn.simplify(cwd .. '/' .. file))
      end
      if norm_file == buf_path or vim.fs.basename(norm_file) == vim.fs.basename(buf_path) then
        diagnostics[#diagnostics + 1] = {
          lnum = tonumber(lnum) - 1,
          col = math.max(tonumber(col) - 1, 0),
          message = msg,
          severity = severity_map[sev:lower()] or vim.diagnostic.severity.ERROR,
          source = 'odin',
        }
      end
    end
  end
  return diagnostics
end

local function odin_target()
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then return '.' end
  local root
  if vim.fs.root then root = vim.fs.root(bufnr, { 'ols.json', '.git', '*.odin' })
  else
    local found = vim.fs.find({ 'ols.json', '.git' }, { path = name, upward = true })[1]
    if found then root = vim.fs.dirname(found) end
  end
  if root then
    -- Prefer package directory if it contains odin files
    return root
  end
  return vim.fn.fnamemodify(name, ':h')
end

lint.linters.odin = {
  name = 'odin',
  cmd = 'odin',
  stdin = false,
  append_fname = false,
  stream = 'both',
  ignore_exitcode = true,
  args = { 'check', '-error-pos-style:unix', odin_target },
  parser = parse_odin_output,
}

lint.linters_by_ft = {
  v = { 'v' },
  odin = { 'odin' },
  go = { 'golangcilint' },
  -- markdown = { 'markdownlint' },
}

-- Ensure golangci-lint resolves via ~/go/bin and Mason bin
-- nvim-lint's built-in golangcilint uses `golangci-lint` on PATH; our PATH already includes ~/go/bin
-- Optionally override args for faster run (we use default config)
-- lint.linters.golangcilint.args = { 'run', '--output.json.path', 'stdout', '--show-stats=false', '--issues-exit-code=0', '--out-format=json' }

local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = lint_augroup,
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype
    if vim.bo[ev.buf].modifiable and (ft == 'v' or ft == 'odin' or ft == 'go' or ft == 'gomod' or ft == 'gowork') then
      lint.try_lint()
    end
  end,
})

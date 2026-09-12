-- V language: run / build / test / vet / fmt via <leader>v*
-- Requires V at ~/.local/share/v (or on PATH). Lint comes from v-analyzer (LSP).

local V_HOME = vim.fn.expand '~/.local/share/v'
local V_BIN = V_HOME .. '/v'

-- Ensure Neovim + child processes (LSP, terminals) can find V
do
  local function prepend_path(dir)
    if dir == '' or vim.fn.isdirectory(dir) == 0 then
      return
    end
    local path = vim.env.PATH or ''
    if not path:find(dir, 1, true) then
      vim.env.PATH = dir .. ':' .. path
    end
  end
  prepend_path(V_HOME)
  prepend_path(vim.fn.stdpath 'data' .. '/mason/bin')
  if vim.fn.isdirectory(V_HOME) == 1 then
    vim.env.VROOT = V_HOME
  end
end

local function v_exe()
  if vim.fn.executable(V_BIN) == 1 then
    return V_BIN
  end
  if vim.fn.executable 'v' == 1 then
    return vim.fn.exepath 'v'
  end
  return nil
end

local function project_root(bufnr)
  bufnr = bufnr or 0
  local markers = { 'v.mod', '.git' }
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    return vim.fn.getcwd()
  end
  local found = vim.fs.find(markers, { path = path, upward = true })[1]
  if found then
    return vim.fs.dirname(found)
  end
  return vim.fn.fnamemodify(path, ':h')
end

local function target_path(bufnr)
  bufnr = bufnr or 0
  local root = project_root(bufnr)
  if vim.fn.filereadable(root .. '/v.mod') == 1 then
    return root
  end
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == '' then
    return root
  end
  return file
end

local function shellescape(s)
  return vim.fn.shellescape(s)
end

local function run_in_term(cmd, cwd)
  cwd = cwd or project_root()
  local ok, Terminal = pcall(function()
    return require('toggleterm.terminal').Terminal
  end)
  if ok and Terminal then
    Terminal:new({
      cmd = cmd,
      dir = cwd,
      direction = 'float',
      close_on_exit = false,
      hidden = true,
    }):toggle()
    return
  end

  vim.cmd('botright split | enew')
  vim.fn.termopen(cmd, { cwd = cwd })
  vim.cmd 'startinsert'
end

local function with_v(fn)
  local exe = v_exe()
  if not exe then
    vim.notify('V not found. Expected ' .. V_BIN .. ' or `v` on PATH', vim.log.levels.ERROR)
    return
  end
  fn(exe)
end

-- Release builds ship a Windows-named tcc.exe; prefer system gcc on Linux.
local CC_ARGS = (vim.fn.executable 'gcc' == 1) and ' -cc gcc' or ''

local function v_run()
  with_v(function(exe)
    local target = target_path()
    run_in_term(shellescape(exe) .. CC_ARGS .. ' run ' .. shellescape(target), project_root())
  end)
end

local function v_build()
  with_v(function(exe)
    local root = project_root()
    local target = target_path()
    local out
    if vim.fn.isdirectory(target) == 1 then
      out = root .. '/' .. vim.fn.fnamemodify(root, ':t')
    else
      out = vim.fn.fnamemodify(target, ':r')
    end
    run_in_term(shellescape(exe) .. CC_ARGS .. ' -o ' .. shellescape(out) .. ' ' .. shellescape(target), root)
  end)
end

local function v_test()
  with_v(function(exe)
    local target = target_path()
    run_in_term(shellescape(exe) .. CC_ARGS .. ' test ' .. shellescape(target), project_root())
  end)
end

local function v_vet()
  with_v(function(exe)
    local target = target_path()
    run_in_term(shellescape(exe) .. ' vet ' .. shellescape(target), project_root())
  end)
end

local function v_fmt()
  -- Prefer LSP (v-analyzer) formatting; fall back to `v fmt -w`
  local ok = pcall(function()
    require('conform').format { async = true, lsp_format = 'prefer' }
  end)
  if ok then
    return
  end
  with_v(function(exe)
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' or not file:match '%.v$' then
      vim.notify('Save a .v file first', vim.log.levels.WARN)
      return
    end
    vim.cmd('write')
    vim.system({ exe, 'fmt', '-w', file }, { text = true }, function(obj)
      vim.schedule(function()
        if obj.code == 0 then
          vim.cmd 'checktime'
          vim.notify('v fmt done', vim.log.levels.INFO)
        else
          vim.notify(obj.stderr ~= '' and obj.stderr or 'v fmt failed', vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true })
end

map('<leader>vr', v_run, '[V] Run')
map('<leader>vb', v_build, '[V] Build')
map('<leader>vt', v_test, '[V] Test')
map('<leader>vv', v_vet, '[V] Vet')
map('<leader>vf', v_fmt, '[V] Format')
map('<leader>vd', function()
  require('telescope.builtin').diagnostics { bufnr = 0 }
end, '[V] Diagnostics (buffer)')

vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add { { '<leader>v', group = '[V]lang' } }
  end
end)

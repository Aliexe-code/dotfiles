-- V language environment setup (PATH + filetype).
-- Shortcuts were removed on request; V LSP (v-analyzer) is configured in init.lua.

-- Define vsh/vv filetypes to silence vim.lsp unknown filetype warning (v_analyzer uses v,vsh,vv)
pcall(function()
  vim.filetype.add({ extension = { vsh = 'v', vv = 'v' } })
end)

local V_HOME = vim.fn.expand '~/.local/share/v'

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

------------------------------------------------------------
-- V helpers
------------------------------------------------------------
local function project_root(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then return vim.fn.getcwd() end
  local found = vim.fs.find({ 'v.mod', '.git' }, { path = name, upward = true })[1]
  if found then return vim.fs.dirname(found) end
  return vim.fn.fnamemodify(name, ':h')
end

local function run_in_term(cmd, cwd)
  cwd = cwd or project_root()
  local ok, Terminal = pcall(function() return require('toggleterm.terminal').Terminal end)
  if ok and Terminal then
    Terminal:new({ cmd = cmd, dir = cwd, direction = 'float', close_on_exit = false, hidden = true }):toggle()
    return
  end
  vim.cmd('botright split | enew')
  vim.fn.termopen(cmd, { cwd = cwd })
  vim.cmd('startinsert')
end

local function shellescape(s) return vim.fn.shellescape(s) end

local function v_run()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then vim.notify('Save a .v file first', vim.log.levels.WARN) return end
  run_in_term('v run ' .. shellescape(file), vim.fn.fnamemodify(file, ':h'))
end

local function v_build()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then vim.notify('Save a .v file first', vim.log.levels.WARN) return end
  local out = vim.fn.fnamemodify(file, ':r')
  run_in_term('v -o ' .. shellescape(out) .. ' ' .. shellescape(file), vim.fn.fnamemodify(file, ':h'))
end

local function v_test()
  run_in_term('v test .', project_root())
end

local function v_fmt()
  local ok = pcall(function() require('conform').format({ async = true, lsp_format = 'fallback' }) end)
  if ok then return end
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then vim.notify('No file', vim.log.levels.WARN) return end
  vim.system({ 'v', 'fmt', '-w', file }, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then vim.cmd('checktime'); vim.notify('v fmt done', vim.log.levels.INFO)
      else vim.notify(obj.stderr ~= '' and obj.stderr or 'v fmt failed', vim.log.levels.ERROR) end
    end)
  end)
end

local function v_check()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then vim.notify('Save a .v file first', vim.log.levels.WARN) return end
  run_in_term('v -check ' .. shellescape(file), vim.fn.fnamemodify(file, ':h'))
end

------------------------------------------------------------
-- V keymaps under <leader>v
------------------------------------------------------------
local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true }) end

map('<leader>vr', v_run, '[V] Run')
map('<leader>vb', v_build, '[V] Build')
map('<leader>vt', v_test, '[V] Test')
map('<leader>vf', v_fmt, '[V] Format')
map('<leader>vc', v_check, '[V] Check')
map('<leader>vh', function() vim.lsp.buf.hover() end, '[V] Hover')
map('<leader>va', function() vim.lsp.buf.code_action() end, '[V] Code action')
map('<leader>vn', function() vim.lsp.buf.rename() end, '[V] Rename')
map('<leader>vg', function() vim.lsp.buf.definition() end, '[V] Goto definition')
map('<leader>vd', function() vim.diagnostic.setloclist() end, '[V] Diagnostics')

vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add({
      { '<leader>v', group = '[V]lang' },
      { '<leader>vr', desc = 'Run' },
      { '<leader>vb', desc = 'Build' },
      { '<leader>vt', desc = 'Test' },
      { '<leader>vf', desc = 'Format' },
      { '<leader>vc', desc = 'Check' },
      { '<leader>vh', desc = 'Hover' },
      { '<leader>va', desc = 'Code action' },
      { '<leader>vn', desc = 'Rename' },
      { '<leader>vg', desc = 'Goto definition' },
      { '<leader>vd', desc = 'Diagnostics' },
    })
  end
end)

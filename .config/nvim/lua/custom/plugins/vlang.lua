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
-- V keymaps — all under <leader>v and <leader>cv
------------------------------------------------------------
vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add {
      { '<leader>v', group = '[V]lang', mode = { 'n', 'v' } },
      { '<leader>cv', group = '[C]ode [V]lang', mode = { 'n', 'v' } },
    }
  end
end)

local function project_root(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then return vim.fn.getcwd() end
  local root = vim.fs.root and vim.fs.root(bufnr, { 'v.mod', '.git' })
  if root then return root end
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
  vim.cmd 'botright split | enew'
  vim.fn.termopen(cmd, { cwd = cwd })
  vim.cmd 'startinsert'
end

local function v_cmd(args, cwd) run_in_term('v ' .. args, cwd or project_root()) end

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true }) end

map('<leader>vr', function() v_cmd('run .') end, '[V] Run (v run .)')
map('<leader>vb', function() v_cmd('build .') end, '[V] Build (v build .)')
map('<leader>vt', function() v_cmd('test .') end, '[V] Test (v test .)')
map('<leader>vf', function() v_cmd('fmt -w .') end, '[V] Format (v fmt -w .)')
map('<leader>vv', function() v_cmd('vet .') end, '[V] Vet (v vet .)')
map('<leader>vc', function() v_cmd('check .') end, '[V] Check (v check .)')
map('<leader>vC', function() v_cmd('clean') end, '[V] Clean')
map('<leader>vdoc', function() v_cmd('doc .') end, '[V] Doc')
map('<leader>vi', function() vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } }, apply = true } end, '[V] Organize imports')

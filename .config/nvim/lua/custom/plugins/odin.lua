-- Odin language: run / build / check / vet via <leader>o*
-- Requires Odin at /usr/bin/odin or /usr/sbin/odin and OLS at mason/bin/ols

-- Ensure Odin bin is on PATH for child processes
do
  local function prepend_path(dir)
    if dir == '' or vim.fn.isdirectory(dir) == 0 then return end
    local path = vim.env.PATH or ''
    if not path:find(dir, 1, true) then vim.env.PATH = dir .. ':' .. path end
  end
  prepend_path(vim.fn.stdpath('data') .. '/mason/bin')
  prepend_path('/usr/lib/odin')
  prepend_path('/usr/sbin')
end

-- Filetype detection for .odin (nvim 0.12+ should handle, but ensure)
vim.filetype.add({
  extension = {
    odin = 'odin',
  },
})

local function odin_exe()
  if vim.fn.executable('/usr/sbin/odin') == 1 then return '/usr/sbin/odin' end
  if vim.fn.executable('/usr/bin/odin') == 1 then return '/usr/bin/odin' end
  if vim.fn.executable('/usr/local/bin/odin') == 1 then return '/usr/local/bin/odin' end
  if vim.fn.executable('odin') == 1 then return vim.fn.exepath('odin') end
  return nil
end

local function project_root(bufnr)
  bufnr = bufnr or 0
  local markers = { 'ols.json', '.git', '*.odin' }
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return vim.fn.getcwd() end
  local found = vim.fs.find(markers, { path = path, upward = true })[1]
  if found then return vim.fs.dirname(found) end
  return vim.fn.fnamemodify(path, ':h')
end

local function shellescape(s) return vim.fn.shellescape(s) end

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

local function with_odin(fn)
  local exe = odin_exe()
  if not exe then
    vim.notify('Odin not found. Expected /usr/sbin/odin or odin on PATH', vim.log.levels.ERROR)
    return
  end
  fn(exe)
end

local function odin_run()
  with_odin(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' run ' .. shellescape(root), root)
  end)
end

local function odin_build()
  with_odin(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' build ' .. shellescape(root) .. ' -o:speed -out:' .. shellescape(root .. '/build.bin'), root)
  end)
end

local function odin_check()
  with_odin(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' check ' .. shellescape(root), root)
  end)
end

local function odin_test()
  with_odin(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' test ' .. shellescape(root), root)
  end)
end

local function odin_check_vet()
  with_odin(function(exe)
    local root = project_root()
    -- -vet checks unused/shadowing/style, -strict-style is alias
    run_in_term(shellescape(exe) .. ' check ' .. shellescape(root) .. ' -vet -vet-unused -vet-shadowing -vet-style', root)
  end)
end

local function odin_build_debug()
  with_odin(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' build ' .. shellescape(root) .. ' -debug -out:' .. shellescape(root .. '/build_debug.bin'), root)
  end)
end

local function odin_build_aggressive()
  with_odin(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' build ' .. shellescape(root) .. ' -o:aggressive -microarch:native -out:' .. shellescape(root .. '/build_aggressive.bin'), root)
  end)
end

local function odin_run_args()
  with_odin(function(exe)
    local root = project_root()
    vim.ui.input({ prompt = 'odin run args: ' }, function(input)
      local args = input and input ~= '' and (' ' .. input) or ''
      run_in_term(shellescape(exe) .. ' run ' .. shellescape(root) .. args, root)
    end)
  end)
end

local function odin_fmt()
  local ok = pcall(function() require('conform').format({ async = true, lsp_format = 'fallback' }) end)
  if not ok then
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' then vim.notify('No file', vim.log.levels.WARN) return end
    local odinfmt = vim.fn.stdpath('data') .. '/mason/bin/odinfmt'
    if vim.fn.executable(odinfmt) ~= 1 then odinfmt = 'odinfmt' end
    vim.system({ odinfmt, file }, { text = true }, function(obj)
      vim.schedule(function()
        if obj.code == 0 then vim.cmd('checktime'); vim.notify('odinfmt done', vim.log.levels.INFO)
        else vim.notify(obj.stderr ~= '' and obj.stderr or 'odinfmt failed', vim.log.levels.ERROR) end
      end)
    end)
  end
end

local function odin_report()
  with_odin(function(exe) run_in_term(shellescape(exe) .. ' report', project_root()) end)
end

local function odin_lint_force()
  -- trigger nvim-lint for odin (odin check)
  local ok, lint = pcall(require, 'lint')
  if ok then lint.try_lint('odin'); vim.notify('odin: lint triggered', vim.log.levels.INFO) end
end

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true }) end

-- Core: Space+o+r/b/t as requested
map('<leader>or', odin_run, '[O]din [R]un (odin run .)')
map('<leader>oR', odin_run_args, '[O]din [R]un with args')
map('<leader>ob', odin_build, '[O]din [B]uild speed')
map('<leader>oB', odin_build_debug, '[O]din [B]uild debug')
map('<leader>oA', odin_build_aggressive, '[O]din [A]ggressive build (native)')
map('<leader>oc', odin_check, '[O]din [C]heck')
map('<leader>ov', odin_check_vet, '[O]din [V]et')
map('<leader>ot', odin_test, '[O]din [T]est')

-- Helpful stuff
map('<leader>of', odin_fmt, '[O]din [F]ormat file')
map('<leader>ol', odin_lint_force, '[O]din [L]int force')
map('<leader>od', function() require('telescope.builtin').diagnostics({ bufnr = 0 }) end, '[O]din [D]iagnostics buffer')
map('<leader>oD', function() require('telescope.builtin').diagnostics() end, '[O]din [D]iagnostics workspace')
map('<leader>os', function() require('telescope.builtin').lsp_document_symbols() end, '[O]din [S]ymbols document')
map('<leader>oS', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, '[O]din [S]ymbols workspace')
map('<leader>oi', function() vim.lsp.buf.hover() end, '[O]din hover [I]nfo')
map('<leader>oa', function() vim.lsp.buf.code_action() end, '[O]din code [A]ction')
map('<leader>on', function() vim.lsp.buf.rename() end, '[O]din re[N]ame')
map('<leader>og', function() vim.lsp.buf.definition() end, '[O]din [G]oto definition')
map('<leader>oh', odin_report, '[O]din [H]elp report')

vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add({
      { '<leader>o', group = '[O]din' },
      { '<leader>or', desc = 'Run' },
      { '<leader>oR', desc = 'Run with args' },
      { '<leader>ob', desc = 'Build speed' },
      { '<leader>oB', desc = 'Build debug' },
      { '<leader>oA', desc = 'Build aggressive' },
      { '<leader>oc', desc = 'Check' },
      { '<leader>ov', desc = 'Vet' },
      { '<leader>ot', desc = 'Test' },
      { '<leader>of', desc = 'Format' },
      { '<leader>ol', desc = 'Lint' },
      { '<leader>od', desc = 'Diagnostics buffer' },
      { '<leader>oD', desc = 'Diagnostics workspace' },
      { '<leader>os', desc = 'Symbols document' },
      { '<leader>oS', desc = 'Symbols workspace' },
      { '<leader>oi', desc = 'Hover info' },
      { '<leader>oa', desc = 'Code action' },
      { '<leader>on', desc = 'Rename' },
      { '<leader>og', desc = 'Goto definition' },
      { '<leader>oh', desc = 'Help report' },
    })
  end
end)

-- Auto-enable OLS for odin filetype if not already enabled via init.lua servers table
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'odin',
  callback = function(ev)
    -- Ensure OLS is enabled (init.lua enables globally, but this is fallback)
    local clients = vim.lsp.get_clients({ bufnr = ev.buf, name = 'ols' })
    if #clients == 0 then
      local mason_ols = vim.fn.stdpath('data') .. '/mason/bin/ols'
      if vim.fn.executable(mason_ols) == 1 then pcall(function() vim.lsp.enable('ols') end) end
    end
  end,
})

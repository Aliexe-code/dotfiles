-- Go language: run / build / test / fmt / vet / tidy via <leader>g*
-- Requires Go at ~/.local/bin/go or go on PATH; gopls via Mason or ~/go/bin.

-- Ensure PATH
do
  local function prepend(dir)
    if dir == '' or vim.fn.isdirectory(dir) == 0 then return end
    local p = vim.env.PATH or ''
    if not p:find(dir, 1, true) then vim.env.PATH = dir .. ':' .. p end
  end
  prepend(vim.fn.expand '~/.local/bin')
  prepend(vim.fn.expand '~/go/bin')
  prepend(vim.fn.stdpath('data') .. '/mason/bin')
  prepend('/usr/local/go/bin')
  prepend('/usr/bin')
end

vim.filetype.add({
  extension = {
    go = 'go',
    gomod = 'gomod',
    gowork = 'gowork',
    gotmpl = 'gotmpl',
  },
})

local function go_exe()
  for _, c in ipairs({ '/usr/local/go/bin/go', vim.fn.expand '~/.local/bin/go', 'go' }) do
    if c == 'go' then
      if vim.fn.executable('go') == 1 then return vim.fn.exepath('go') end
    elseif vim.fn.executable(c) == 1 then
      return c
    end
  end
  return nil
end

local function project_root(bufnr)
  bufnr = bufnr or 0
  local markers = { 'go.mod', 'go.work', '.git' }
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return vim.fn.getcwd() end
  local found = vim.fs.find(markers, { path = path, upward = true })[1]
  if found then return vim.fs.dirname(found) end
  return vim.fn.fnamemodify(path, ':h')
end

local function has_go_mod(dir)
  return vim.fn.filereadable(dir .. '/go.mod') == 1
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

local function with_go(fn)
  local exe = go_exe()
  if not exe then
    vim.notify('Go not found. Expected ~/.local/bin/go or go on PATH', vim.log.levels.ERROR)
    return
  end
  fn(exe)
end

local function go_run()
  with_go(function(exe)
    local root = project_root()
    if has_go_mod(root) then
      run_in_term(shellescape(exe) .. ' run .', root)
    else
      local file = vim.api.nvim_buf_get_name(0)
      if file == '' or not file:match('%.go$') then
        vim.notify('Save a .go file first', vim.log.levels.WARN)
        return
      end
      run_in_term(shellescape(exe) .. ' run ' .. shellescape(file), vim.fn.fnamemodify(file, ':h'))
    end
  end)
end

local function go_run_args()
  with_go(function(exe)
    local root = project_root()
    vim.ui.input({ prompt = 'go run args: ' }, function(input)
      local args = input and input ~= '' and (' ' .. input) or ''
      if has_go_mod(root) then
        run_in_term(shellescape(exe) .. ' run .' .. args, root)
      else
        local file = vim.api.nvim_buf_get_name(0)
        if file == '' then vim.notify('No file', vim.log.levels.WARN) return end
        run_in_term(shellescape(exe) .. ' run ' .. shellescape(file) .. args, vim.fn.fnamemodify(file, ':h'))
      end
    end)
  end)
end

local function go_build()
  with_go(function(exe)
    local root = project_root()
    if has_go_mod(root) then
      run_in_term(shellescape(exe) .. ' build ./...', root)
    else
      local file = vim.api.nvim_buf_get_name(0)
      if file == '' then vim.notify('Save a .go file first', vim.log.levels.WARN) return end
      local out = vim.fn.fnamemodify(file, ':r')
      run_in_term(shellescape(exe) .. ' build -o ' .. shellescape(out) .. ' ' .. shellescape(file), vim.fn.fnamemodify(file, ':h'))
    end
  end)
end

local function go_build_race()
  with_go(function(exe)
    local root = project_root()
    if has_go_mod(root) then
      run_in_term(shellescape(exe) .. ' build -race ./...', root)
    else
      vim.notify('No go.mod found', vim.log.levels.WARN)
    end
  end)
end

local function go_test()
  with_go(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' test -v ./...', root)
  end)
end

local function current_test_name()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)
  for i = #lines, 1, -1 do
    local name = lines[i]:match('^func%s+(Test%w+)%s*%(')
      or lines[i]:match('^func%s+(Benchmark%w+)%s*%(')
      or lines[i]:match('^func%s+(Example%w*)%s*%(')
    if name then return name end
  end
  return nil
end

local function go_test_current()
  with_go(function(exe)
    local file = vim.api.nvim_buf_get_name(0)
    local dir = file ~= '' and vim.fn.fnamemodify(file, ':h') or project_root()
    local name = current_test_name()
    if name then
      run_in_term(shellescape(exe) .. ' test -run ' .. shellescape('^' .. name .. '$') .. ' -v .', dir)
    else
      run_in_term(shellescape(exe) .. ' test -v .', dir)
    end
  end)
end

local function go_test_cover()
  with_go(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' test -coverprofile=coverage.out ./... && ' .. shellescape(exe) .. ' tool cover -html=coverage.out', root)
  end)
end

local function go_vet()
  with_go(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' vet ./...', root)
  end)
end

local function go_tidy()
  with_go(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' mod tidy', root)
  end)
end

local function go_generate()
  with_go(function(exe)
    local root = project_root()
    run_in_term(shellescape(exe) .. ' generate ./...', root)
  end)
end

local function go_get()
  with_go(function(exe)
    vim.ui.input({ prompt = 'go get: ' }, function(input)
      if not input or input == '' then return end
      local root = project_root()
      run_in_term(shellescape(exe) .. ' get ' .. input, root)
    end)
  end)
end

local function go_mod_init()
  with_go(function(exe)
    vim.ui.input({ prompt = 'module path: ' }, function(input)
      if not input or input == '' then return end
      local root = project_root()
      run_in_term(shellescape(exe) .. ' mod init ' .. shellescape(input), root)
    end)
  end)
end

local function go_fmt()
  local ok = pcall(function() require('conform').format({ async = true, lsp_format = 'fallback' }) end)
  if ok then return end
  with_go(function(_)
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' then vim.notify('No file', vim.log.levels.WARN) return end
    vim.system({ 'gofmt', '-w', file }, { text = true }, function(obj)
      vim.schedule(function()
        if obj.code == 0 then vim.cmd('checktime'); vim.notify('gofmt done', vim.log.levels.INFO)
        else vim.notify(obj.stderr ~= '' and obj.stderr or 'gofmt failed', vim.log.levels.ERROR) end
      end)
    end)
  end)
end

local function go_lint()
  vim.schedule(function()
    local lint_ok, lint = pcall(require, 'lint')
    if lint_ok then lint.try_lint() end
  end)
  vim.notify('golangci-lint: running...', vim.log.levels.INFO)
end

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true }) end

map('<leader>gr', go_run, '[G]o [R]un')
map('<leader>gR', go_run_args, '[G]o [R]un with args')
map('<leader>gb', go_build, '[G]o [B]uild')
map('<leader>gB', go_build_race, '[G]o [B]uild (race)')
map('<leader>gt', go_test, '[G]o [T]est (all)')
map('<leader>gT', go_test_current, '[G]o [T]est (current)')
map('<leader>gc', go_test_cover, '[G]o [C]overage')
map('<leader>gv', go_vet, '[G]o [V]et')
map('<leader>gi', go_tidy, '[G]o mod t[I]dy')
map('<leader>gg', go_generate, '[G]o [G]enerate')
map('<leader>gl', go_lint, '[G]o [L]int')
map('<leader>gf', go_fmt, '[G]o [F]ormat')
map('<leader>gM', go_mod_init, '[G]o [M]od init')
map('<leader>gG', go_get, '[G]o [G]et module')

map('<leader>gd', function() require('telescope.builtin').diagnostics({ bufnr = 0 }) end, '[G]o [D]iagnostics buffer')
map('<leader>gD', function() require('telescope.builtin').diagnostics() end, '[G]o [D]iagnostics workspace')
map('<leader>gs', function() require('telescope.builtin').lsp_document_symbols() end, '[G]o [S]ymbols document')
map('<leader>gS', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, '[G]o [S]ymbols workspace')
map('<leader>gh', function() vim.lsp.buf.hover() end, '[G]o [H]over')
map('<leader>gA', function() vim.lsp.buf.code_action() end, '[G]o code [A]ction')
map('<leader>gn', function() vim.lsp.buf.rename() end, '[G]o re[N]ame')
map('<leader>gq', function() vim.diagnostic.setloclist() end, '[G]o [Q]uickfix')
map('<leader>g]', function() vim.lsp.buf.definition() end, '[G]o goto def')

vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add({
      { '<leader>g', group = '[G]o' },
      { '<leader>gr', desc = 'Run' },
      { '<leader>gR', desc = 'Run with args' },
      { '<leader>gb', desc = 'Build' },
      { '<leader>gB', desc = 'Build (race)' },
      { '<leader>gt', desc = 'Test (all)' },
      { '<leader>gT', desc = 'Test (current)' },
      { '<leader>gc', desc = 'Coverage' },
      { '<leader>gv', desc = 'Vet' },
      { '<leader>gi', desc = 'Mod tidy' },
      { '<leader>gg', desc = 'Generate' },
      { '<leader>gl', desc = 'Lint' },
      { '<leader>gf', desc = 'Format' },
      { '<leader>gM', desc = 'Mod init' },
      { '<leader>gG', desc = 'Get module' },
      { '<leader>gd', desc = 'Diagnostics buffer' },
      { '<leader>gD', desc = 'Diagnostics workspace' },
      { '<leader>gs', desc = 'Symbols document' },
      { '<leader>gS', desc = 'Symbols workspace' },
      { '<leader>gh', desc = 'Hover' },
      { '<leader>gA', desc = 'Code action' },
      { '<leader>gn', desc = 'Rename' },
      { '<leader>gq', desc = 'Quickfix' },
      { '<leader>g]', desc = 'Goto def' },
    })
  end
end)

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  callback = function(ev)
    local clients = vim.lsp.get_clients({ bufnr = ev.buf, name = 'gopls' })
    if #clients == 0 then
      pcall(function() vim.lsp.enable('gopls') end)
    end
  end,
})

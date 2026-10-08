-- Zig language: run / build / test / fmt / ast-check / fetch via <leader>z*
-- Requires Zig 0.17.x at /usr/bin/zig and ZLS (mason/bin/zls or zls on PATH)
-- NOTE: 0.17 renamed -O modes to lowercase (debug/safe/fast/small).
-- Old names (Debug/ReleaseFast/...) still parse but are deprecated (removed after 0.18).

-- Ensure Mason and Zig bins are on PATH for LSP, conform, and :terminal
do
  local function prepend_path(dir)
    if dir == '' or vim.fn.isdirectory(dir) == 0 then return end
    local path = vim.env.PATH or ''
    if not path:find(dir, 1, true) then vim.env.PATH = dir .. ':' .. path end
  end
  prepend_path(vim.fn.stdpath('data') .. '/mason/bin')
  prepend_path('/usr/bin')
  prepend_path('/usr/local/bin')
end

-- Filetype detection for .zig / .zon (Neovim 0.12 handles .zig, ensure .zon)
vim.filetype.add({
  extension = {
    zig = 'zig',
    zon = 'zig',
  },
})

local function zig_exe()
  if vim.fn.executable('/usr/bin/zig') == 1 then return '/usr/bin/zig' end
  if vim.fn.executable('/usr/local/bin/zig') == 1 then return '/usr/local/bin/zig' end
  if vim.fn.executable('zig') == 1 then return vim.fn.exepath('zig') end
  return nil
end

local function has_build_zig(dir)
  return vim.fn.filereadable(dir .. '/build.zig') == 1 or vim.fn.filereadable(dir .. '/build.zig.zon') == 1
end

local function project_root(bufnr)
  bufnr = bufnr or 0
  local markers = { 'build.zig', 'build.zig.zon', '.git' }
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

local function with_zig(fn)
  local exe = zig_exe()
  if not exe then
    vim.notify('Zig not found. Expected /usr/bin/zig or zig on PATH (0.17.x)', vim.log.levels.ERROR)
    return
  end
  fn(exe)
end

-- === Actions ===

local function zig_run()
  with_zig(function(exe)
    local root = project_root()
    if has_build_zig(root) then
      -- Project mode: zig build run (uses run step if defined)
      run_in_term(shellescape(exe) .. ' build run', root)
    else
      local file = vim.api.nvim_buf_get_name(0)
      if file == '' or not file:match('%.zig$') then
        vim.notify('Save a .zig file first', vim.log.levels.WARN)
        return
      end
      run_in_term(shellescape(exe) .. ' run ' .. shellescape(file), vim.fn.fnamemodify(file, ':h'))
    end
  end)
end

local function zig_run_args()
  with_zig(function(exe)
    local root = project_root()
    vim.ui.input({ prompt = 'zig run args: ' }, function(input)
      local args = input and input ~= '' and (' ' .. input) or ''
      if has_build_zig(root) then
        run_in_term(shellescape(exe) .. ' build run --' .. args, root)
      else
        local file = vim.api.nvim_buf_get_name(0)
        if file == '' then vim.notify('No file', vim.log.levels.WARN) return end
        -- 0.17: `zig run` requires `--` before program args, else "unrecognized file extension"
        local sep = (args == '') and '' or (' --' .. args)
        run_in_term(shellescape(exe) .. ' run ' .. shellescape(file) .. sep, vim.fn.fnamemodify(file, ':h'))
      end
    end)
  end)
end

local function zig_build()
  with_zig(function(exe)
    local root = project_root()
    if has_build_zig(root) then
      -- 0.17: -Doptimize takes debug/safe/fast/small (lowercase)
      run_in_term(shellescape(exe) .. ' build -Doptimize=fast', root)
    else
      local file = vim.api.nvim_buf_get_name(0)
      if file == '' then vim.notify('Save a .zig file first', vim.log.levels.WARN) return end
      local out = vim.fn.fnamemodify(file, ':r')
      run_in_term(shellescape(exe) .. ' build-exe ' .. shellescape(file) .. ' -O fast -femit-bin=' .. shellescape(out) .. ' --cache-dir /tmp/zig-cache --global-cache-dir /tmp/zig-global-cache', vim.fn.fnamemodify(file, ':h'))
    end
  end)
end

local function zig_build_pick()
  with_zig(function(exe)
    local root = project_root()
    if has_build_zig(root) then
      vim.ui.select({ 'debug', 'safe', 'fast', 'small', 'fast + cpu=native' }, { prompt = 'zig build optimize:' }, function(choice)
        if not choice then return end
        -- 0.17: `zig build` has no -mcpu flag (unrecognized argument). Use -Dcpu= instead.
        local opt = '-Doptimize=fast'
        local cpu = ''
        if choice == 'debug' then opt = '-Doptimize=debug'
        elseif choice == 'safe' then opt = '-Doptimize=safe'
        elseif choice == 'small' then opt = '-Doptimize=small'
        elseif choice:find('native') then cpu = ' -Dcpu=native' end
        run_in_term(shellescape(exe) .. ' build ' .. opt .. cpu, root)
      end)
    else
      vim.ui.select({ 'debug', 'safe', 'fast', 'small', 'fast + mcpu=native' }, { prompt = 'zig build-exe optimize:' }, function(choice)
        if not choice then return end
        local file = vim.api.nvim_buf_get_name(0)
        if file == '' then vim.notify('Save a .zig file first', vim.log.levels.WARN) return end
        local out = vim.fn.fnamemodify(file, ':r')
        -- 0.17: `zig build-exe` -O takes debug/safe/fast/small; -mcpu is valid here (unlike `zig build`)
        local zig_opt = 'fast'
        local mcpu = ''
        if choice == 'debug' then zig_opt = 'debug'
        elseif choice == 'safe' then zig_opt = 'safe'
        elseif choice == 'small' then zig_opt = 'small'
        elseif choice:find('native') then mcpu = ' -mcpu=native' end
        run_in_term(shellescape(exe) .. ' build-exe ' .. shellescape(file) .. ' -O ' .. zig_opt .. mcpu .. ' -femit-bin=' .. shellescape(out) .. ' --cache-dir /tmp/zig-cache --global-cache-dir /tmp/zig-global-cache', vim.fn.fnamemodify(file, ':h'))
      end)
    end
  end)
end

local function zig_test()
  with_zig(function(exe)
    local root = project_root()
    if has_build_zig(root) then
      run_in_term(shellescape(exe) .. ' build test --summary all', root)
    else
      local file = vim.api.nvim_buf_get_name(0)
      if file == '' then vim.notify('Save a .zig file first', vim.log.levels.WARN) return end
      run_in_term(shellescape(exe) .. ' test ' .. shellescape(file), vim.fn.fnamemodify(file, ':h'))
    end
  end)
end

local function zig_ast_check()
  with_zig(function(exe)
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' then vim.notify('Save a .zig file first', vim.log.levels.WARN) return end
    run_in_term(shellescape(exe) .. ' ast-check ' .. shellescape(file), vim.fn.fnamemodify(file, ':h'))
  end)
end

local function zig_check()
  with_zig(function(exe)
    local root = project_root()
    local file = vim.api.nvim_buf_get_name(0)
    if has_build_zig(root) then
      run_in_term(shellescape(exe) .. ' ast-check ' .. shellescape(file) .. ' && ' .. shellescape(exe) .. ' build --fetch', root)
    else
      zig_ast_check()
    end
  end)
end

local function zig_fmt()
  local ok = pcall(function() require('conform').format({ async = true, lsp_format = 'fallback' }) end)
  if ok then return end
  with_zig(function(exe)
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' then vim.notify('No file', vim.log.levels.WARN) return end
    vim.system({ exe, 'fmt', file }, { text = true }, function(obj)
      vim.schedule(function()
        if obj.code == 0 then vim.cmd('checktime'); vim.notify('zig fmt done', vim.log.levels.INFO)
        else vim.notify(obj.stderr ~= '' and obj.stderr or 'zig fmt failed', vim.log.levels.ERROR) end
      end)
    end)
  end)
end

local function zig_fetch()
  with_zig(function(exe)
    vim.ui.input({ prompt = 'zig fetch --save <url or path>: ' }, function(input)
      if not input or input == '' then return end
      run_in_term(shellescape(exe) .. ' fetch --save ' .. shellescape(input), project_root())
    end)
  end)
end

local function zig_init()
  with_zig(function(exe)
    vim.ui.input({ prompt = 'zig init in dir (default: cwd): ' }, function(input)
      local dir = (input and input ~= '') and input or project_root()
      -- 0.17: `zig init` scaffolds full exe+lib, `zig init --minimal` scaffolds stub build.zig
      vim.ui.select({ 'full (exe+lib)', 'minimal (stub)' }, { prompt = 'zig init template:' }, function(choice)
        if not choice then return end
        local flag = choice:find('minimal') and ' --minimal' or ''
        run_in_term(shellescape(exe) .. ' init' .. flag, dir)
      end)
    end)
  end)
end

local function zig_version()
  with_zig(function(exe) run_in_term(shellescape(exe) .. ' version && ' .. shellescape(exe) .. ' env', project_root()) end)
end

-- === Keymaps ===

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true }) end

-- Core: Space+z+r/b/t as requested
map('<leader>zr', zig_run, '[Z]ig [R]un')
map('<leader>zR', zig_run_args, '[Z]ig [R]un with args')
map('<leader>zb', zig_build, '[Z]ig [B]uild')
map('<leader>zB', zig_build_pick, '[Z]ig [B]uild pick (debug/safe/fast/small/native)')
map('<leader>zt', zig_test, '[Z]ig [T]est')
map('<leader>za', zig_ast_check, '[Z]ig [A]st-check')
map('<leader>zc', zig_check, '[Z]ig [C]heck')
map('<leader>zf', zig_fmt, '[Z]ig [F]ormat file')
map('<leader>zF', zig_fetch, '[Z]ig [F]etch --save')
map('<leader>zi', zig_init, '[Z]ig [I]nit')
map('<leader>zv', zig_version, '[Z]ig [V]ersion/env')

-- Diagnostics / LSP helpers (like odin.lua)
map('<leader>zd', function() require('telescope.builtin').diagnostics({ bufnr = 0 }) end, '[Z]ig [D]iagnostics buffer')
map('<leader>zD', function() require('telescope.builtin').diagnostics() end, '[Z]ig [D]iagnostics workspace')
map('<leader>zs', function() require('telescope.builtin').lsp_document_symbols() end, '[Z]ig [S]ymbols document')
map('<leader>zS', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, '[Z]ig [S]ymbols workspace')
map('<leader>zh', function() vim.lsp.buf.hover() end, '[Z]ig [H]over')
map('<leader>zH', function() vim.lsp.buf.hover() end, '[Z]ig [H]over')
map('<leader>zA', function() vim.lsp.buf.code_action() end, '[Z]ig code [A]ction')
map('<leader>zn', function() vim.lsp.buf.rename() end, '[Z]ig re[N]ame')
map('<leader>zg', function() vim.lsp.buf.definition() end, '[Z]ig [G]oto definition')
map('<leader>zq', function() vim.diagnostic.setloclist() end, '[Z]ig [Q]uickfix')

vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add({
      { '<leader>z', group = '[Z]ig' },
      { '<leader>zr', desc = 'Run' },
      { '<leader>zR', desc = 'Run with args' },
      { '<leader>zb', desc = 'Build' },
      { '<leader>zB', desc = 'Build pick' },
      { '<leader>zt', desc = 'Test' },
      { '<leader>za', desc = 'Ast-check' },
      { '<leader>zc', desc = 'Check' },
      { '<leader>zf', desc = 'Format' },
      { '<leader>zF', desc = 'Fetch' },
      { '<leader>zi', desc = 'Init' },
      { '<leader>zv', desc = 'Version' },
      { '<leader>zd', desc = 'Diagnostics buffer' },
      { '<leader>zD', desc = 'Diagnostics workspace' },
      { '<leader>zs', desc = 'Symbols document' },
      { '<leader>zS', desc = 'Symbols workspace' },
      { '<leader>zh', desc = 'Hover' },
      { '<leader>zA', desc = 'Code action' },
      { '<leader>zn', desc = 'Rename' },
      { '<leader>zg', desc = 'Goto definition' },
      { '<leader>zq', desc = 'Quickfix' },
    })
  end
end)

-- Auto-enable ZLS for zig filetype if not already enabled via init.lua servers table
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'zig',
  callback = function(ev)
    local clients = vim.lsp.get_clients({ bufnr = ev.buf, name = 'zls' })
    if #clients == 0 then
      local mason_zls = vim.fn.stdpath('data') .. '/mason/bin/zls'
      if vim.fn.executable(mason_zls) == 1 or vim.fn.executable('zls') == 1 then pcall(function() vim.lsp.enable('zls') end) end
    end
  end,
})

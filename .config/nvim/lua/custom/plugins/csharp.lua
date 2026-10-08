-- C# / .NET development: Roslyn LSP + formatting + DAP + dotnet CLI keymaps
-- Requires: .NET SDK on PATH (you have 10.0.x at /usr/sbin/dotnet),
--   Mason packages: roslyn-language-server, csharpier, netcoredbg
--   (auto-installed via init.lua ensure_installed on next :MasonToolInstallerInstall)

-- Ensure Mason + dotnet bins are on PATH for LSP, conform, lint, and :terminal
do
  local function prepend_path(dir)
    if dir == '' or vim.fn.isdirectory(dir) == 0 then return end
    local p = vim.env.PATH or ''
    if not p:find(dir, 1, true) then vim.env.PATH = dir .. ':' .. p end
  end
  prepend_path(vim.fn.stdpath('data') .. '/mason/bin')
  prepend_path('/usr/sbin') -- dotnet lives here on this machine (CachyOS)
  prepend_path('/usr/share/dotnet')
  prepend_path(vim.fn.expand('~/.dotnet/tools')) -- dotnet global tools (csharpier fallback)
end

------------------------------------------------------------
-- Treesitter: ensure C# parser installed (idempotent)
------------------------------------------------------------
pcall(function()
  require('nvim-treesitter').install({ 'c_sharp' })
end)

------------------------------------------------------------
-- LSP: Roslyn (Microsoft.CodeAnalysis.LanguageServer)
-- via seblyng/roslyn.nvim — handles the pipe transport that
-- plain vim.lsp.config can't. Do NOT also enable omnisharp.
------------------------------------------------------------
vim.pack.add {
  'https://github.com/seblyng/roslyn.nvim',
}

pcall(function()
  require('roslyn').setup({
    -- Mason package `roslyn-language-server` is picked up automatically.
    -- Broaden target selection so solution/project picking works in big repos:
    broad_search = true,
    lock_target = true,
    filewatching = 'roslyn',
    -- Inlay hints / codelens follow your global <leader>th toggle (kickstart-lsp-attach).
    config = {
      settings = {
        ['csharp|inlay_hints'] = {
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          csharp_enable_inlay_hints_for_lambda_parameter_types = true,
          csharp_enable_inlay_hints_for_types = true,
          dotnet_enable_inlay_hints_for_indexer_parameters = true,
          dotnet_enable_inlay_hints_for_literal_parameters = true,
          dotnet_enable_inlay_hints_for_object_creation_parameters = true,
          dotnet_enable_inlay_hints_for_other_parameters = true,
          dotnet_enable_inlay_hints_for_parameters = true,
          dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
          dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
          dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
        },
        ['csharp|code_lens'] = {
          dotnet_enable_references_code_lens = true,
          dotnet_enable_tests_code_lens = true,
        },
        ['csharp|completion'] = {
          dotnet_show_name_completion_suggestions = true,
          dotnet_show_completion_items_from_unimported_namespaces = true,
        },
      },
    },
  })
end)

------------------------------------------------------------
-- DAP: netcoredbg (C# debugger)
------------------------------------------------------------
pcall(function()
  local dap = require('dap')
  local mason_bin = vim.fn.stdpath('data') .. '/mason/bin/netcoredbg'
  local cmd = vim.fn.executable(mason_bin) == 1 and mason_bin or 'netcoredbg'
  if dap.adapters and not dap.adapters.coreclr then
    dap.adapters.coreclr = {
      type = 'executable',
      command = cmd,
      args = { '--interpreter=vscode' },
    }
  end
  if dap.configurations and not dap.configurations.cs then
    dap.configurations.cs = {
      {
        type = 'coreclr',
        name = 'launch - netcoredbg',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
        end,
      },
    }
  end
end)

------------------------------------------------------------
-- Helpers: run dotnet commands in toggleterm float (fallback: :terminal split)
------------------------------------------------------------
local function sln_root(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then return vim.fn.getcwd() end
  local root = vim.fs.root and vim.fs.root(bufnr, { '*.sln', '*.csproj', '.git' })
  if root then return root end
  local found = vim.fs.find({ '*.sln', '*.csproj', '.git' }, { path = name, upward = true })[1]
  if found then return vim.fs.dirname(found) end
  return vim.fn.fnamemodify(name, ':h')
end

local function run_in_term(cmd, cwd)
  cwd = cwd or sln_root()
  local ok, Terminal = pcall(function() return require('toggleterm.terminal').Terminal end)
  if ok and Terminal then
    Terminal:new({ cmd = cmd, dir = cwd, direction = 'float', close_on_exit = false, hidden = true }):toggle()
    return
  end
  vim.cmd('botright split | enew')
  vim.fn.termopen(cmd, { cwd = cwd })
  vim.cmd('startinsert')
end

local function dotnet(args) run_in_term('dotnet ' .. args, sln_root()) end

local function dotnet_test_under_cursor()
  -- Runs the test method/class under cursor via --filter FullyQualifiedName~Name
  local name = vim.fn.expand('<cword>')
  if name == '' then
    vim.notify('No test name under cursor', vim.log.levels.WARN)
    return
  end
  dotnet('test --filter "FullyQualifiedName~' .. name .. '"')
end

------------------------------------------------------------
-- Keymaps — all under <leader>cd ([C]ode [D]otnet), no clashes with
-- <leader>cf (format), <leader>cg (go), <leader>d (debug), <leader>z (zig)
------------------------------------------------------------
vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if ok then wk.add({ { '<leader>cd', group = '[C]ode [D]otnet' } }) end
end)

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true }) end

map('<leader>cdr', function() dotnet('run') end, '[C]ode [D]otnet Run')
map('<leader>cdw', function() dotnet('watch run') end, '[C]ode [D]otnet Watch run')
map('<leader>cdb', function() dotnet('build') end, '[C]ode [D]otnet Build')
map('<leader>cdt', function() dotnet('test') end, '[C]ode [D]otnet Test all')
map('<leader>cdT', dotnet_test_under_cursor, '[C]ode [D]otnet Test under cursor')
map('<leader>cde', function() dotnet('restore') end, '[C]ode [D]otnet rEstore')
map('<leader>cdf', function() require('conform').format({ async = true }) end, '[C]ode [D]otnet Format (csharpier)')
map('<leader>cdm', function()
  vim.ui.input({ prompt = 'migration name: ' }, function(input)
    if input and input ~= '' then dotnet('ef migrations add ' .. input) end
  end)
end, '[C]ode [D]otnet Migration add')
map('<leader>cdu', function() dotnet('ef database update') end, '[C]ode [D]otnet DB Update')

-- LSP helpers scoped to C# buffers (global gr* maps already exist; these are shortcuts)
map('<leader>cdd', function() require('telescope.builtin').diagnostics({ bufnr = 0 }) end, '[C]ode [D]otnet Diagnostics buffer')
map('<leader>cdD', function() require('telescope.builtin').diagnostics() end, '[C]ode [D]otnet Diagnostics workspace')
map('<leader>cds', function() require('telescope.builtin').lsp_document_symbols() end, '[C]ode [D]otnet Symbols document')
map('<leader>cdh', function() vim.lsp.buf.hover() end, '[C]ode [D]otnet Hover')
map('<leader>cda', function() vim.lsp.buf.code_action() end, '[C]ode [D]otnet code Action')
map('<leader>cdn', function() vim.lsp.buf.rename() end, '[C]ode [D]otnet reName')
map('<leader>cdg', function() vim.lsp.buf.definition() end, '[C]ode [D]otnet Goto definition')

------------------------------------------------------------
-- Filetype tweaks
------------------------------------------------------------
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'cs', 'csproj', 'sln' },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.expandtab = true -- C# uses spaces (csharpier default)
    vim.bo.commentstring = '// %s'
  end,
})

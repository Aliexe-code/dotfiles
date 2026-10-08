-- Go development: full IDE support for Kickstart
-- Covers gopls (configured in init.lua), formatting (conform + gofumpt/goimports/golines),
-- linting (golangci-lint via nvim-lint), DAP (delve), treesitter, and handy keymaps.

-- Ensure Go/Mason binaries are on PATH for LSP, conform, lint, and :terminal
do
  local function prepend_path(dir)
    if dir == '' or vim.fn.isdirectory(dir) == 0 then return end
    local p = vim.env.PATH or ''
    if not p:find(dir, 1, true) then vim.env.PATH = dir .. ':' .. p end
  end
  prepend_path(vim.fn.expand '~/go/bin')
  prepend_path(vim.fn.stdpath 'data' .. '/mason/bin')
  -- Also ensure shell for new terminals inherits it
  vim.env.GOPATH = vim.fn.expand '~/go'
end

------------------------------------------------------------
-- Treesitter: ensure Go parsers installed (idempotent)
------------------------------------------------------------
pcall(function()
  local parsers = { 'go', 'gomod', 'gosum', 'gowork' }
  require('nvim-treesitter').install(parsers)
end)

------------------------------------------------------------
-- Extra Go plugins: go.nvim + gopher.nvim
------------------------------------------------------------
-- go.nvim provides GoImport, GoTestFunc, GoAlt, GoFillStruct, etc.
vim.pack.add {
  'https://github.com/nvim-lua/plenary.nvim', -- already present, ensures availability
  'https://github.com/nvim-treesitter/nvim-treesitter',
  { src = 'https://github.com/ray-x/go.nvim', version = vim.version.range '*' },
  'https://github.com/ray-x/guihua.lua',
  'https://github.com/olexsmir/gopher.nvim',
}

-- go.nvim setup — deliberately light: we keep conform for formatting and nvim-lint for linting
-- to avoid duplicate formatting/diagnostics. go.nvim mainly gives commands & code actions.
-- Stub legacy nvim-treesitter modules for go.nvim (we use nvim-treesitter@main which removed these)
if not pcall(require, 'nvim-treesitter.configs') then
  package.loaded['nvim-treesitter.configs'] = {
    setup = function() end,
    get_parser_configs = function() return {} end,
  }
end
if not pcall(require, 'nvim-treesitter.info') then
  package.loaded['nvim-treesitter.info'] = {
    installed_parsers = function()
      local ok, ts = pcall(require, 'nvim-treesitter')
      if ok and ts.get_installed then
        local ok2, res = pcall(ts.get_installed, 'parsers')
        if ok2 and type(res) == 'table' then return res end
      end
      return {}
    end,
  }
end
-- Define gotmpl filetype to silence vim.lsp unknown filetype warning (gopls uses it)
pcall(function()
  vim.filetype.add({ extension = { tmpl = 'gotmpl', gotmpl = 'gotmpl' } })
end)
pcall(function()
  require('go').setup {
    -- we handle formatting via conform + gopls gofumpt; disable go.nvim's formatter
    gofmt = 'gofumpt',
    goimports = 'gopls',
    fillstruct = 'gopls',
    lsp_cfg = false, -- do NOT reconfigure gopls (already done in init.lua)
    lsp_gofumpt = true,
    lsp_on_attach = false,
    dap_debug = true,
    dap_debug_gui = true,
    test_runner = 'go',
    verbose = false,
    -- tag options
    tag_transform = false,
    -- keep lsp diagnostics from gopls; don't duplicate
    lsp_inlay_hints = { enable = true },
  }
  -- auto-install go binaries that go.nvim needs if missing (gofumpt etc already installed)
  -- We skip the default 'gopls' because we already manage it via Mason/~/go/bin
end)

pcall(function()
  require('gopher').setup {
    commands = {
      go = 'go',
      gomodifytags = 'gomodifytags',
      gotests = 'gotests',
      impl = 'impl',
      iferr = 'iferr', -- if installed
    },
  }
end)

------------------------------------------------------------
-- Helpers: run Go commands in toggleterm/float
------------------------------------------------------------
local function project_root(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then return vim.fn.getcwd() end
  local root = vim.fs.root and vim.fs.root(bufnr, { 'go.mod', 'go.work', '.git' })
  if root then return root end
  local found = vim.fs.find({ 'go.mod', 'go.work', '.git' }, { path = name, upward = true })[1]
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

local function go_cmd(args, cwd) run_in_term('go ' .. args, cwd or project_root()) end

------------------------------------------------------------
-- Go keymaps — all under <leader>g and <leader>c
------------------------------------------------------------
-- Ensure which-key shows Go group
vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add {
      { '<leader>g', group = '[G]o', mode = { 'n', 'v' } },
      { '<leader>cg', group = '[C]ode [G]o', mode = { 'n', 'v' } },
    }
  end
end)

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true }) end

-- Run / Build / Test (toggleterm)
map('<leader>gr', function() go_cmd('run .') end, '[G]o Run (go run .)')
map('<leader>gb', function() go_cmd 'build ./...' end, '[G]o Build (go build ./...)')
map('<leader>gt', function() go_cmd 'test ./... -v' end, '[G]o Test (go test ./...)')
map('<leader>gT', function() go_cmd('test -run ' .. vim.fn.expand '<cword>' .. ' -v') end, '[G]o Test func under cursor')
map('<leader>gv', function() go_cmd 'vet ./...' end, '[G]o Vet')
map('<leader>gl', function()
  local lint = require 'lint'
  lint.try_lint 'golangcilint'
  vim.notify('golangci-lint triggered', vim.log.levels.INFO)
end, '[G]o Lint (golangci-lint)')
map('<leader>gc', function() go_cmd('vet ./... && test ./...') end, '[G]o Check (vet + test)')
map('<leader>gm', function() go_cmd 'mod tidy' end, '[G]o Mod tidy')
map('<leader>gi', function()
  -- Organize imports via gopls code action
  vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } }, apply = true }
end, '[G]o Imports organize')

-- go.nvim commands (when available)
map('<leader>ga', '<cmd>GoAlt<cr>', '[G]o Alt (impl ↔ test)')
map('<leader>gf', '<cmd>GoFillStruct<cr>', '[G]o Fill struct')
map('<leader>ge', '<cmd>GoIfErr<cr>', '[G]o If err')
map('<leader>gA', '<cmd>GoAddTag<cr>', '[G]o Add struct tags')
map('<leader>gR', '<cmd>GoRmTag<cr>', '[G]o Remove struct tags')
map('<leader>gd', '<cmd>GoDoc<cr>', '[G]o Doc')
map('<leader>gD', function() require('dap-go').debug_test() end, '[G]o Debug test')

-- gopher.nvim
map('<leader>gs', '<cmd>GoTagAdd json<cr>', '[G]o Tag add json')
map('<leader>gS', '<cmd>GoTagRm json<cr>', '[G]o Tag rm json')
map('<leader>gI', '<cmd>GoImpl<cr>', '[G]o Impl interface')
map('<leader>gE', '<cmd>GoTestsAdd<cr>', '[G]o Tests add')
map('<leader>gC', '<cmd>GoCmt<cr>', '[G]o Comment')

-- Code group mirrors (for <leader>c*)
map('<leader>cgr', function() go_cmd('run .') end, '[C]ode [G]o Run')
map('<leader>cgt', function() go_cmd 'test ./... -v' end, '[C]ode [G]o Test')
map('<leader>cgb', function() go_cmd 'build ./...' end, '[C]ode [G]o Build')

-- Visual mode: extract etc. handled by go.nvim if needed

------------------------------------------------------------
-- LSP: Go-specific on_attach extras
------------------------------------------------------------
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('go-lsp-attach', { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or client.name ~= 'gopls' then return end
    local buf = ev.buf

    -- Auto-organize imports on save? keep conform formatting + gopls organizes via code action fallback
    -- We do explicit BufWritePre organizeImports for Go (in addition to conform's goimports)
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = buf,
      group = vim.api.nvim_create_augroup('go-imports-' .. buf, { clear = true }),
      callback = function()
        -- Use gopls organizeImports synchronously with timeout
        local params = vim.lsp.util.make_range_params(0, 'utf-8')
        params.context = { only = { 'source.organizeImports' } }
        local result = vim.lsp.buf_request_sync(buf, 'textDocument/codeAction', params, 800)
        if not result then return end
        for cid, res in pairs(result) do
          for _, r in pairs(res.result or {}) do
            if r.edit then
              local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or 'utf-16'
              vim.lsp.util.apply_workspace_edit(r.edit, enc)
            end
          end
        end
      end,
    })

    -- Go inlay hints already enabled via gopls hints; toggle with <leader>th (existing)
    -- Extra: show gopls version in :LspInfo style notify on first attach
    vim.notify('gopls attached (' .. (client.config.cmd and client.config.cmd[1] or 'gopls') .. ')', vim.log.levels.DEBUG)
  end,
})

------------------------------------------------------------
-- DAP: ensure nvim-dap-go is configured (debug.lua already does it),
-- but re-ensure here in case that file is not loaded yet when this runs
------------------------------------------------------------
pcall(function()
  local dapgo = require 'dap-go'
  dapgo.setup {
    delve = { detached = vim.fn.has 'win32' == 0 },
    tests = { verbose = true },
  }
end)

-- Additional DAP keymaps specific to Go (keep F-keys from debug.lua, add <leader>dg)
map('<leader>dgt', function() require('dap-go').debug_test() end, 'Debug Go Test')
map('<leader>dgl', function() require('dap-go').debug_last_test() end, 'Debug Go Last Test')
map('<leader>dgd', function() require('dap').continue() end, 'Debug Go Continue')

------------------------------------------------------------
-- Filetype tweaks
------------------------------------------------------------
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'go', 'gomod', 'gowork', 'gotmpl' },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.expandtab = false -- Go uses tabs
    vim.bo.commentstring = '// %s'
  end,
})

-- Highlight go err handling nicely (optional)
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  callback = function()
    -- no-op: placeholder for future Go filetype customizations
  end,
})

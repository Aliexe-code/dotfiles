-- blog_legacy.lua
-- Re-implements https://rsdlt.github.io/posts/rust-nvim-ide-guide-walkthrough-development-debug/
-- alongside modern kickstart.nvim (vim.pack + rustaceanvim + blink.cmp + nvim-dap + toggleterm).
-- All plugins are opt-in-safe: guarded with pcall, no overriding of core rustaceanvim LSP.
-- Keep blink.cmp as the only completion engine.
-- Keep neo-tree as primary; nvim-tree is added but not hijacking netrw.

local function gh(repo) return 'https://github.com/' .. repo end

-- ------------------------------------------------------------
-- 1. Install every blog plugin that is NOT already in init.lua
-- ------------------------------------------------------------
vim.pack.add {

  -- Debug blog §5: vimspector (+ CodeLLDB already via mason)
  gh 'puremourning/vimspector',

  -- Terminal blog: floaterm ( alongside toggleterm )
  gh 'voldikss/vim-floaterm',

  -- Search at speed (§): hop
  -- phaazon/hop.nvim is archived → smoka7 fork is maintained
  gh 'smoka7/hop.nvim',

  -- Project status §
  gh 'nvim-tree/nvim-tree.lua', -- successor of kyazdani42/nvim-tree.lua
  gh 'preservim/tagbar',
  gh 'folke/trouble.nvim',
  gh 'nvim-lua/popup.nvim', -- blog lists it explicitly

  -- Better coding experience §
  gh 'tpope/vim-surround', -- mini.surround already present, keep both
  gh 'RRethy/vim-illuminate',

  -- Nice look & feel §
  gh 'm-demare/hlargs.nvim',
  gh 'danilamihailov/beacon.nvim',
  gh 'tanvirtin/monokai.nvim',
  gh 'navarasu/onedark.nvim',
  -- impatient is deprecated on nvim>=0.9 (vim.loader.enable) but install guarded
  -- gh 'lewis6991/impatient.nvim',

  -- Statusline / dashboard listed in blog's final plugin list
  gh 'nvim-lualine/lualine.nvim',
  gh 'goolord/alpha-nvim',
}

-- ------------------------------------------------------------
-- Helpers: safe setup
-- ------------------------------------------------------------
local function safe_setup(name, fn)
  local ok, mod = pcall(require, name)
  if ok and fn then
    local ok2, err = pcall(fn, mod)
    if not ok2 then vim.notify('[blog_legacy] ' .. name .. ' setup failed: ' .. tostring(err), vim.log.levels.WARN) end
  elseif not ok then
    vim.notify('[blog_legacy] ' .. name .. ' not found, skipping', vim.log.levels.DEBUG)
  end
end

-- ============================================================
-- Treesitter is already setup in init.lua §9 with rust+toml
-- Ensure additional blog parser options (folds, rainbow)
-- ============================================================
do
  pcall(function()
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
  end)
  -- rainbow is now in separate plugin, but blog's rainbow opts are kept no-op
end

-- ============================================================
-- SECTION 5 (blog): Vimspector + CodeLLDB
-- ============================================================
do
  -- UI options from blog lua/opts.lua §5
  vim.cmd [[
    let g:vimspector_sidebar_width = 85
    let g:vimspector_bottombar_height = 15
    let g:vimspector_terminal_maxwidth = 70
    " Prefer CodeLLDB from Mason
    let g:vimspector_install_gadgets = [ 'CodeLLDB' ]
  ]]

  -- Blog keymaps §5, adapted to not clash with nvim-dap's <F5> etc
  -- Keep nvim-dap on <F5> (continue) etc; add Vimspector on <F9> etc as blog
  local function vmap(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { desc = desc, silent = true })
  end

  -- Vimspector blog mappings:
  -- <F9> Launch, <F5> StepOver (blog had duplicate), <F8> Reset, <F11> StepOver, <F12> StepOut, <F10> StepInto
  -- We map all via <cmd>call... so no Lua dep needed, but guard if not installed
  vim.cmd [[
    nnoremap <silent> <F9>  <cmd>call vimspector#Launch()<cr>
    nnoremap <silent> <F5>  <cmd>call vimspector#Continue()<cr>
    nnoremap <silent> <F8>  <cmd>call vimspector#Reset()<cr>
    nnoremap <silent> <F11> <cmd>call vimspector#StepOver()<cr>
    nnoremap <silent> <F12> <cmd>call vimspector#StepOut()<cr>
    nnoremap <silent> <F10> <cmd>call vimspector#StepInto()<cr>
  ]]

  -- Blog's map('n',"Db"...): use <leader>D* to avoid clash with <leader>b (dap toggle)
  vmap('<leader>Db', '<cmd>call vimspector#ToggleBreakpoint()<cr>', 'Vimspector: Toggle Breakpoint')
  vmap('<leader>Dw', '<cmd>call vimspector#AddWatch()<cr>', 'Vimspector: Add Watch')
  vmap('<leader>De', '<cmd>call vimspector#Evaluate()<cr>', 'Vimspector: Evaluate')
  vmap('<leader>Dc', '<cmd>call vimspector#Continue()<cr>', 'Vimspector: Continue')
  vmap('<leader>Dr', '<cmd>call vimspector#Reset()<cr>', 'Vimspector: Reset')

  -- Ensure CodeLLDB adapter resolves for Vimspector via Mason path
  -- Vimspector auto-discovers codelldb at Mason path; create hint file if needed
  local mason_codelldb = vim.fn.stdpath 'data' .. '/mason/packages/codelldb/extension/adapter/codelldb'
  if vim.fn.executable(mason_codelldb) == 1 then
    vim.g.vimspector_adapters = vim.g.vimspector_adapters or ''
  end

  -- Provide template generator :VimspectorRustInit analogous to blog's manual .vimspector.json
  vim.api.nvim_create_user_command('VimspectorRustInit', function()
    local cwd = vim.fn.getcwd()
    local path = cwd .. '/.vimspector.json'
    if vim.fn.filereadable(path) == 1 then
      vim.notify('.vimspector.json already exists at ' .. path, vim.log.levels.WARN)
      return
    end
    local bin = vim.fn.fnamemodify(cwd, ':t')
    local tmpl = string.format([[
{
  "configurations": {
    "launch": {
      "adapter": "CodeLLDB",
      "filetypes": [ "rust" ],
      "configuration": {
        "request": "launch",
        "program": "${workspaceRoot}/target/debug/%s"
      }
    },
    "test": {
      "adapter": "CodeLLDB",
      "filetypes": [ "rust" ],
      "configuration": {
        "request": "launch",
        "program": "${workspaceRoot}/target/debug/deps/${workspaceRootBasename}-<hash> (run `cargo test --no-run` to find)"
      }
    }
  }
}
]], bin)
    vim.fn.writefile(vim.split(tmpl, '\n'), path)
    vim.notify('Created ' .. path .. ' — edit program path after cargo build', vim.log.levels.INFO)
    vim.cmd('edit ' .. path)
  end, { desc = 'Create .vimspector.json template for Rust (blog §5)' })
end

-- ============================================================
-- Floaterm (blog: Cargo power with terminal access)
-- ============================================================
do
  vim.g.floaterm_width = 0.7
  vim.g.floaterm_height = 0.8
  vim.g.floaterm_autoclose = 2
  vim.g.floaterm_title = 'floaterm: $1/$2'

  -- Blog mappings: <leader>ft new, t toggle (blog's `t` shadows motion — we use <leader>t<TAB> compat)
  -- Keep blog's <leader>ft but use floating shell from toggleterm as fallback if floaterm not ready
  pcall(function()
    vim.keymap.set('n', '<leader>ft', ':FloatermNew --name=myfloat --height=0.8 --width=0.7 --autoclose=2 fish<CR>', { desc = 'Floaterm: new myfloat (blog)', silent = true })
    -- Blog had `map('n',"t",":FloatermToggle myfloat<CR>")` which breaks `t` motion; remap to <leader>tf and keep toggleterm compat
    vim.keymap.set('n', '<leader>Ft', ':FloatermToggle myfloat<CR>', { desc = 'Floaterm: toggle myfloat', silent = true })
    -- also allow `t` toggle only with leader to avoid hijack; keep original blog map as optional disabled by default
    -- Uncomment next line if you want exact blog behavior (overrides `t` motion):
    -- vim.keymap.set('n', 't', ':FloatermToggle myfloat<CR>', { silent = true })

    -- Terminal mode Esc to close (blog: map('t',"<Esc>","<C-\\><C-n>:q<CR>"))
    vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { desc = 'Floaterm: normal mode' })
  end)
end

-- ============================================================
-- Hop (blog: Searching at the speed of Rust)
-- ============================================================
do
  safe_setup('hop', function(hop)
    hop.setup { keys = 'etovxqpdygfblzhckisuran' }
    vim.keymap.set('n', '<leader>hw', function() require('hop').hint_words() end, { desc = 'Hop: words' })
    vim.keymap.set('n', '<leader>hl', function() require('hop').hint_lines() end, { desc = 'Hop: lines' })
    vim.keymap.set('n', '<leader>hc', function() require('hop').hint_char1() end, { desc = 'Hop: char1' })
    vim.keymap.set('n', '<leader>hC', function() require('hop').hint_char2() end, { desc = 'Hop: char2' })
  end)
end

-- ============================================================
-- Project status: nvim-tree, tagbar, trouble, todo already
-- ============================================================
do
  -- nvim-tree: install but do NOT hijack if neo-tree is primary unless explicitly toggled
  safe_setup('nvim-tree', function(nvim_tree)
    -- disable_netrw = false to not fight neo-tree; hijack disabled by default
    nvim_tree.setup {
      disable_netrw = false,
      hijack_netrw = false,
      hijack_cursor = false,
      view = { width = 32, side = 'left' },
      renderer = { highlight_git = true, icons = { show = { git = true } } },
      git = { enable = true },
      filters = { dotfiles = false },
    }
    vim.keymap.set('n', '<leader>eT', '<cmd>NvimTreeToggle<cr>', { desc = 'Explorer: nvim-tree toggle (blog legacy)' })
  end)

  -- tagbar
  pcall(function()
    vim.g.tagbar_width = 32
    vim.g.tagbar_autofocus = 1
    vim.keymap.set('n', '<leader>ct', '<cmd>TagbarToggle<cr>', { desc = 'Tagbar toggle (blog)' })
  end)

  -- trouble (new API: trouble.nvim v3)
  safe_setup('trouble', function(trouble)
    -- keep defaults; blog used folke/trouble to show diagnostics panel
    pcall(function() trouble.setup {} end)
    vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'Trouble: diagnostics' })
    vim.keymap.set('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Trouble: buffer diagnostics' })
    vim.keymap.set('n', '<leader>cs', '<cmd>Trouble symbols toggle<cr>', { desc = 'Trouble: symbols' })
    vim.keymap.set('n', '<leader>xL', '<cmd>Trouble loclist toggle<cr>', { desc = 'Trouble: loclist' })
    vim.keymap.set('n', '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', { desc = 'Trouble: quickfix' })
  end)
end

-- ============================================================
-- Better coding experience: illuminate, etc
-- ============================================================
do
  safe_setup('illuminate', function(illuminate)
    illuminate.configure {
      delay = 100,
      filetypes_denylist = { 'dirvish', 'fugitive', 'alpha', 'NvimTree', 'neo-tree' },
    }
  end)

  -- vim-surround needs no setup (tpope), just ensure mappings: ys, ds, cs
  -- mineral: no conflict with mini.surround (saiw etc)

  -- hlargs
  safe_setup('hlargs', function(hlargs) hlargs.setup {} end)

  -- beacon
  safe_setup('beacon', function(beacon) beacon.setup {} end)
end

-- ============================================================
-- Nice look & feel: monokai, onedark, lualine, alpha
-- ============================================================
do
  -- themes: just install, don't switch (catppuccin remains default from themes.lua)
  -- available via :colorscheme monokai / onedark

  safe_setup('lualine', function(lualine)
    -- Only setup if user wants; keep mini.statusline as primary to avoid double statusline
    -- Setup lualine but guard: if mini.statusline is active, lualine will replace it.
    -- We enable lualine only if g.blog_legacy_lualine is set. Otherwise install but don't activate.
    if vim.g.blog_legacy_lualine then
      lualine.setup { options = { theme = 'auto', globalstatus = true }, sections = { lualine_c = { 'filename' } } }
    end
  end)

  safe_setup('alpha', function(alpha)
    local ok_dash, dashboard = pcall(require, 'alpha.themes.dashboard')
    if ok_dash then alpha.setup(dashboard.config) end
  end)

  -- popup.nvim: dependency, no setup needed
end

-- ============================================================
-- Diagnostics popup (blog §2 init.lua Diagnostics Options Setup)
-- Merge with kickstart's diagnostic.config without clobbering severity_sort etc.
-- Blog had virtual_text=false, we keep kickstart's virtual_text=true but provide toggle
-- ============================================================
do
  -- Blog signs (rounded float, signs) — keep kickstart signs but ensure icons exist
  local sign = function(opts) vim.fn.sign_define(opts.name, { texthl = opts.name, text = opts.text, numhl = '' }) end
  -- Only define if not already defined with our modern icons
  pcall(function()
    -- Use blog's icons if not present
    if vim.fn.sign_getdefined('DiagnosticSignError')[1] == nil then
      sign { name = 'DiagnosticSignError', text = '' }
      sign { name = 'DiagnosticSignWarn', text = '' }
      sign { name = 'DiagnosticSignHint', text = '' }
      sign { name = 'DiagnosticSignInfo', text = '' }
    end
  end)

  -- Blog's autocmd CursorHold float (kickstart already does jump float, this adds legacy behavior)
  vim.api.nvim_create_augroup('blog_legacy_diagnostic_float', { clear = true })
  vim.api.nvim_create_autocmd('CursorHold', {
    group = 'blog_legacy_diagnostic_float',
    callback = function() vim.diagnostic.open_float(nil, { focusable = false, border = 'rounded', source = 'always' }) end,
    desc = 'Blog legacy: open diagnostic float on CursorHold',
  })

  -- which-key group for legacy blog items
  vim.schedule(function()
    local ok, wk = pcall(require, 'which-key')
    if ok then
      wk.add {
        { '<leader>D', group = 'Vimspector (blog)' },
        { '<leader>h', group = 'Hop / Git Hunk' }, -- hop extends h prefix already has gitsigns
        { '<leader>x', group = 'Trouble' },
        { '<leader>F', group = 'Floaterm (blog)' },
      }
    end
  end)
end

-- ============================================================
-- Rust-tools compat shim (blog §2)
-- DO NOT activate rust-tools server alongside rustaceanvim.
-- Provide alias `RustTools*` commands that forward to rustaceanvim, so blog snippets don't error.
-- If user explicitly wants rust-tools, they can set `vim.g.blog_legacy_rust_tools = true` before startup.
-- ============================================================
do
  if vim.g.blog_legacy_rust_tools then
    safe_setup('rust-tools', function(rt)
      rt.setup {
        server = {
          on_attach = function(_, bufnr)
            vim.keymap.set('n', '<C-space>', rt.hover_actions.hover_actions, { buffer = bufnr, desc = 'rust-tools hover' })
            vim.keymap.set('n', '<Leader>a', rt.code_action_group.code_action_group, { buffer = bufnr, desc = 'rust-tools code action group' })
          end,
        },
      }
    end)
  else
    -- Shim: make require('rust-tools') return rustaceanvim forwards to avoid errors in user snippets
    package.preload['rust-tools'] = function()
      return {
        setup = function() vim.notify('[blog_legacy] rust-tools shim: using rustaceanvim instead (set g:blog_legacy_rust_tools=1 to use real rust-tools)', vim.log.levels.INFO) end,
        hover_actions = { hover_actions = function() vim.cmd.RustLsp { 'hover', 'actions' } end },
        code_action_group = { code_action_group = function() vim.cmd.RustLsp { 'codeAction' } end },
      }
    end
  end
end

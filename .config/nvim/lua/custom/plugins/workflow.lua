-- Explorer, terminal, search, and navigation — IDE-style Space shortcuts

vim.pack.add {
  { src = 'https://github.com/akinsho/toggleterm.nvim', version = vim.version.range '*' },
  'https://github.com/numToStr/Comment.nvim',
}

require('Comment').setup()

------------------------------------------------------------
-- File explorer (neo-tree) — Space + e
------------------------------------------------------------
-- Left sidebar toggle; works from normal mode
vim.keymap.set('n', '<leader>e', '<Cmd>Neotree filesystem toggle left<CR>', {
  desc = 'Explorer: toggle',
  silent = true,
})
vim.keymap.set('n', '<leader>o', '<Cmd>Neotree filesystem focus left<CR>', {
  desc = 'Explorer: focus',
  silent = true,
})

-- Improve neo-tree defaults (left, git status, close on file open optional)
pcall(function()
  require('neo-tree').setup {
    close_if_last_window = true,
    popup_border_style = 'rounded',
    filesystem = {
      follow_current_file = { enabled = true },
      hijack_netrw_behavior = 'open_current',
      filtered_items = {
        visible = false,
        hide_dotfiles = false,
        hide_gitignored = true,
      },
      window = {
        position = 'left',
        width = 32,
        mappings = {
          ['<leader>e'] = 'close_window',
          ['\\'] = 'close_window',
          ['l'] = 'open',
          ['h'] = 'close_node',
          ['<space>'] = 'toggle_node',
        },
      },
    },
    window = {
      mappings = {
        ['<leader>e'] = 'close_window',
      },
    },
  }
end)

------------------------------------------------------------
-- Terminal — Space + tt / `  + easy window switching
------------------------------------------------------------
require('toggleterm').setup {
  size = function(term)
    if term.direction == 'horizontal' then
      return 15
    elseif term.direction == 'vertical' then
      return vim.o.columns * 0.4
    end
  end,
  open_mapping = false, -- we set our own
  hide_numbers = true,
  shade_terminals = true,
  start_in_insert = true,
  insert_mappings = true,
  terminal_mappings = true,
  persist_size = true,
  persist_mode = true,
  direction = 'float',
  close_on_exit = true,
  shell = vim.o.shell,
  float_opts = {
    border = 'rounded',
    winblend = 0,
  },
}

local Terminal = require('toggleterm.terminal').Terminal
local float_term = Terminal:new { direction = 'float', hidden = true }
local horiz_term = Terminal:new { direction = 'horizontal', hidden = true }
local vert_term = Terminal:new { direction = 'vertical', hidden = true }

local function toggle_float()
  float_term:toggle()
end
local function toggle_horiz()
  horiz_term:toggle()
end
local function toggle_vert()
  vert_term:toggle()
end

-- Primary terminal toggles
vim.keymap.set({ 'n', 't' }, '<leader>tt', function()
  -- Leave terminal-mode first when toggling from inside a terminal
  if vim.fn.mode() == 't' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true), 'n', false)
  end
  vim.schedule(toggle_float)
end, { desc = 'Terminal: toggle float' })

vim.keymap.set({ 'n', 't' }, '<leader>`', function()
  if vim.fn.mode() == 't' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true), 'n', false)
  end
  vim.schedule(toggle_float)
end, { desc = 'Terminal: toggle float' })

vim.keymap.set('n', '<leader>ts', toggle_horiz, { desc = 'Terminal: toggle horizontal' })
vim.keymap.set('n', '<leader>tv', toggle_vert, { desc = 'Terminal: toggle vertical' })

-- Easy leave terminal → normal mode (then use Ctrl-hjkl / Space+e)
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { desc = 'Terminal: normal mode' })
vim.keymap.set('t', 'jk', [[<C-\><C-n>]], { desc = 'Terminal: normal mode' })

-- Switch windows from terminal mode (back to editor / explorer)
vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], { desc = 'Window left' })
vim.keymap.set('t', '<C-j>', [[<C-\><C-n><C-w>j]], { desc = 'Window down' })
vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], { desc = 'Window up' })
vim.keymap.set('t', '<C-l>', [[<C-\><C-n><C-w>l]], { desc = 'Window right' })

-- From normal mode: jump back into a terminal buffer if visible
vim.keymap.set('n', '<leader>tf', function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == 'terminal' then
      vim.api.nvim_set_current_win(win)
      vim.cmd 'startinsert'
      return
    end
  end
  toggle_float()
end, { desc = 'Terminal: focus / open' })

------------------------------------------------------------
-- Search — clear Space shortcuts (files + text)
------------------------------------------------------------
local ok_tele, builtin = pcall(require, 'telescope.builtin')
if ok_tele then
  -- Prefer system ripgrep/fd when available (avoid shadowed toolchains on PATH)
  local rg = vim.fn.executable '/usr/bin/rg' == 1 and '/usr/bin/rg' or 'rg'
  local fd = vim.fn.executable '/usr/bin/fd' == 1 and '/usr/bin/fd' or (vim.fn.executable 'fd' == 1 and 'fd' or nil)

  pcall(function()
    local telescope = require 'telescope'
    telescope.setup {
      defaults = {
        vimgrep_arguments = {
          rg,
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
          '--hidden',
          '--glob',
          '!.git/*',
        },
        file_ignore_patterns = { 'node_modules', '.git/', 'target/', 'dist/' },
      },
      pickers = {
        find_files = fd and {
          find_command = { fd, '--type', 'f', '--hidden', '--exclude', '.git' },
        } or {},
      },
    }
  end)

  -- Short aliases (easier to remember than s*)
  vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Find text (grep)' })
  vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = 'Find word under cursor' })
  vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
  vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = 'Find recent files' })
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Find help' })
  vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Find keymaps' })
  vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Find diagnostics' })
  vim.keymap.set('n', '<leader>fc', builtin.commands, { desc = 'Find commands' })
  vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols, { desc = 'Find symbols (buffer)' })
  vim.keymap.set('n', '<leader>fS', builtin.lsp_workspace_symbols, { desc = 'Find symbols (workspace)' })
  vim.keymap.set('n', '<leader>f/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = 'Find in current buffer' })

  -- Hidden files search
  vim.keymap.set('n', '<leader>fF', function()
    builtin.find_files { hidden = true, no_ignore = false }
  end, { desc = 'Find files (incl. hidden)' })
end

------------------------------------------------------------
-- Buffers & windows
------------------------------------------------------------
vim.keymap.set('n', '<leader>bd', '<Cmd>bdelete<CR>', { desc = 'Buffer: delete' })
vim.keymap.set('n', '<leader>bn', '<Cmd>bnext<CR>', { desc = 'Buffer: next' })
vim.keymap.set('n', '<leader>bp', '<Cmd>bprevious<CR>', { desc = 'Buffer: prev' })
vim.keymap.set('n', '<S-l>', '<Cmd>bnext<CR>', { desc = 'Buffer: next' })
vim.keymap.set('n', '<S-h>', '<Cmd>bprevious<CR>', { desc = 'Buffer: prev' })

vim.keymap.set('n', '<leader>wv', '<Cmd>vsplit<CR>', { desc = 'Window: vertical split' })
vim.keymap.set('n', '<leader>ws', '<Cmd>split<CR>', { desc = 'Window: horizontal split' })
vim.keymap.set('n', '<leader>wd', '<Cmd>close<CR>', { desc = 'Window: close' })
vim.keymap.set('n', '<leader>wo', '<Cmd>only<CR>', { desc = 'Window: only' })

-- Save / quit helpers
vim.keymap.set('n', '<leader>ww', '<Cmd>w<CR>', { desc = 'Write file' })
vim.keymap.set('n', '<leader>qq', '<Cmd>qa<CR>', { desc = 'Quit all' })

-- Toggle comments on selected text or the current section
vim.keymap.set({ 'n', 'v' }, '<leader>R', 'gc', { desc = 'Toggle comment (line/selection)', remap = true })

------------------------------------------------------------
-- which-key groups (Space menu)
------------------------------------------------------------
vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if not ok then
    return
  end
  wk.add {
    { '<leader>e', desc = 'Explorer toggle' },
    { '<leader>o', desc = 'Explorer focus' },
    { '<leader>f', group = '[F]ind' },
    { '<leader>t', group = '[T]erminal / Toggle' },
    { '<leader>b', group = '[B]uffer' },
    { '<leader>c', group = '[C]ode' },
    { '<leader>w', group = '[W]indow / Write' },
    { '<leader>`', desc = 'Terminal float' },
    { '<leader><leader>', desc = 'Buffers' },
  }
end)

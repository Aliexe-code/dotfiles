-- Git workflow — LazyGit TUI + Telescope pickers.
-- Hunk-level actions (stage/reset/blame/diff) live with gitsigns in init.lua (<leader>h*).

vim.pack.add {
  'https://github.com/kdheepak/lazygit.nvim', -- no tagged releases: track default branch
  'https://github.com/nvim-lua/plenary.nvim', -- float decoration (already present)
}

-- Full git TUI (stage, commit, push/pull, branch, rebase, stash) in a floating window.
vim.keymap.set('n', '<leader>hg', '<cmd>LazyGit<cr>', { desc = 'Git: LazyGit (TUI)', silent = true })

-- Quick Telescope pickers.
vim.keymap.set('n', '<leader>hf', '<cmd>Telescope git_files<cr>', { desc = 'Git: files (tracked)', silent = true })
vim.keymap.set('n', '<leader>hc', '<cmd>Telescope git_commits<cr>', { desc = 'Git: commits (repo)', silent = true })
vim.keymap.set('n', '<leader>hl', '<cmd>Telescope git_bcommits<cr>', { desc = 'Git: commits (buffer)', silent = true })
vim.keymap.set('n', '<leader>hB', '<cmd>Telescope git_branches<cr>', { desc = 'Git: branches', silent = true })

-- Track visited repos so `:Telescope lazygit` can switch between them (e.g. submodules).
require('telescope').load_extension 'lazygit'

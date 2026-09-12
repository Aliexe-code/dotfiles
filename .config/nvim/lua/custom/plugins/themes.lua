-- Colorscheme plugins (vim.pack managed)
vim.pack.add {
  { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
  { src = 'https://github.com/rebelot/kanagawa.nvim', name = 'kanagawa' },
  { src = 'https://github.com/rose-pine/neovim', name = 'rose-pine' },
  { src = 'https://github.com/Erl-koenig/theme-hub.nvim', name = 'theme-hub' },
  'https://github.com/nvim-lua/plenary.nvim',
}

-- Apply default on startup
vim.cmd.colorscheme('catppuccin-mocha')

-- Setup theme selector
vim.schedule(function()
  local ok, theme_hub = pcall(require, 'theme-hub')
  if ok then
    theme_hub.setup {
      install_dir = vim.fn.stdpath('data') .. '/theme-hub',
      persistent = true,
    }
  end
end)
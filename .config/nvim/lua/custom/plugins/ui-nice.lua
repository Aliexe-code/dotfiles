-- Nice UI: noice (cmdline popup), dressing (input/select), notify, transparent helpers

vim.pack.add {
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/rcarriga/nvim-notify',
  'https://github.com/folke/noice.nvim',
  'https://github.com/stevearc/dressing.nvim',
}

-- nvim-notify as vim.notify (so noice + other plugins use it)
pcall(function()
  local notify = require('notify')
  notify.setup {
    background_colour = '#1e1e2e',
    stages = 'fade',
    timeout = 2500,
    render = 'compact',
    top_down = false,
  }
  vim.notify = notify
end)

-- dressing: better vim.ui.input / vim.ui.select (used by zig.lua fetch prompts etc.)
pcall(function()
  require('dressing').setup {
    input = {
      enabled = true,
      border = 'rounded',
      relative = 'cursor',
      prefer_width = 50,
    },
    select = {
      enabled = true,
      backend = { 'telescope', 'builtin' },
      builtin = { border = 'rounded' },
    },
  }
end)

-- noice: cmdline, messages, lsp progress as popup (keeps fidget for lsp)
pcall(function()
  require('noice').setup {
    lsp = {
      -- keep fidget for progress; noice shows hover/signature
      progress = { enabled = false },
      override = {
        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
        ['vim.lsp.util.stylize_markdown'] = true,
        ['cmp.entry.get_documentation'] = true,
      },
    },
    presets = {
      bottom_search = true, -- use classic bottom cmdline for search
      command_palette = true, -- position cmdline and popupmenu together
      long_message_to_split = true,
      inc_rename = false,
      lsp_doc_border = true,
    },
    cmdline = {
      view = 'cmdline_popup', -- nice centered popup
      format = {
        cmdline = { icon = '' },
        search_down = { icon = ' ' },
        search_up = { icon = ' ' },
        filter = { icon = '$' },
        lua = { icon = '' },
        help = { icon = '' },
      },
    },
    messages = { view_search = false },
    popupmenu = { enabled = true, backend = 'nui' },
    views = {
      cmdline_popup = { border = { style = 'rounded' }, position = { row = 8, col = '50%' } },
      hover = { border = { style = 'rounded' } },
    },
    routes = {
      -- hide noisy "written" messages; show as notify instead
      { filter = { event = 'msg_show', kind = '', find = 'written' }, opts = { skip = true } },
    },
  }
  -- which-key for noice
  vim.keymap.set('n', '<leader>un', '<cmd>Noice dismiss<CR>', { desc = 'Dismiss Noice messages' })
  vim.keymap.set('n', '<leader>uN', '<cmd>Noice history<CR>', { desc = 'Noice history' })
end)

-- Optional transparent toggle <leader>ut (keeps catppuccin/tokyonight)
pcall(function()
  -- transparent by default already set below; ensure toggle respects autocmd
  vim.keymap.set('n', '<leader>ut', function()
    if vim.g.transparent_enabled then
      -- restore opaque: disable flag before colorscheme so ColorScheme autocmd doesn't re-transparent
      vim.g.transparent_enabled = false
      vim.cmd('colorscheme catppuccin-mocha')
      vim.notify('Transparent OFF (opaque)', vim.log.levels.INFO)
    else
      vim.g.transparent_enabled = true
      vim.cmd('hi Normal guibg=NONE ctermbg=NONE | hi NormalNC guibg=NONE | hi NormalFloat guibg=NONE | hi SignColumn guibg=NONE | hi LineNr guibg=NONE | hi EndOfBuffer guibg=NONE')
      vim.notify('Transparent ON', vim.log.levels.INFO)
    end
  end, { desc = 'Toggle Transparent' })
end)

-- Register which-key group for UI nice
vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if ok then wk.add({ { '<leader>u', group = '[U]I / Nice' }, { '<leader>un', desc = 'Dismiss Noice' } }) end
end)

-- Transparent by default as requested
vim.g.transparent_enabled = true
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    if vim.g.transparent_enabled then
      vim.cmd('hi Normal guibg=NONE ctermbg=NONE | hi NormalNC guibg=NONE | hi NormalFloat guibg=NONE | hi SignColumn guibg=NONE | hi LineNr guibg=NONE | hi EndOfBuffer guibg=NONE')
    end
  end,
})
vim.schedule(function()
  if vim.g.transparent_enabled then
    vim.cmd('hi Normal guibg=NONE ctermbg=NONE | hi NormalNC guibg=NONE | hi NormalFloat guibg=NONE | hi SignColumn guibg=NONE | hi LineNr guibg=NONE | hi EndOfBuffer guibg=NONE')
  end
end)

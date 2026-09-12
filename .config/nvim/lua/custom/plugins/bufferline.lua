-- Bufferline: show open buffers at top with navigation
vim.pack.add {
  'https://github.com/akinsho/bufferline.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
}

vim.schedule(function()
  local ok, bufferline = pcall(require, 'bufferline')
  if ok then
    bufferline.setup {
      options = {
        mode = 'buffers',
        show_buffer_close_icons = true,
        show_close_icon = false,
        show_tab_indicators = true,
        separator_style = 'thin',
        enforce_regular_bg = true,
        diagnostics = 'nvim_lsp',
        diagnostics_indicator = function(_, _, diag)
          local icons = { error = 'E', warn = 'W', info = 'I', hint = 'H' }
          local out = {}
          for _, d in ipairs { 'error', 'warn', 'info', 'hint' } do
            if diag[d] and diag[d] > 0 then
              table.insert(out, icons[d] .. diag[d])
            end
          end
          return table.concat(out, ' ')
        end,
      },
    }
  end
end)

-- Buffer navigation
vim.keymap.set('n', '<S-h>', '<Cmd>BufferLineCyclePrev<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<S-l>', '<Cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<C-S-h>', '<Cmd>BufferLineMovePrev<CR>', { desc = 'Move buffer left' })
vim.keymap.set('n', '<C-S-l>', '<Cmd>BufferLineMoveNext<CR>', { desc = 'Move buffer right' })
vim.keymap.set('n', '<leader>bc', '<Cmd>BufferLinePickClose<CR>', { desc = 'Close buffer' })
vim.keymap.set('n', '<leader>ba', '<Cmd>BufferLinePick<CR>', { desc = 'Pick buffer to close' })
vim.keymap.set({ 'n', 'v' }, '<leader>1', '<C-\\><C-n><Cmd>1wincmd w<CR>', { desc = 'Go to window 1' })
-- Data helpers: csv preview + sqlite/postgres via dadbod

vim.pack.add {
  'https://github.com/tpope/vim-dadbod',
  'https://github.com/kristijanhusak/vim-dadbod-ui',
  'https://github.com/kristijanhusak/vim-dadbod-completion',
  'https://github.com/hat0uma/csvview.nvim',
}

-- csvview: table view for .csv/.tsv, toggle <leader>cv
pcall(function()
  require('csvview').setup {
    view = { display_mode = 'border' },
    parser = { comments = { '#', '//' } },
    keymaps = {
      textobject_field_inner = { 'if', mode = { 'o', 'x' } },
      textobject_field_outer = { 'af', mode = { 'o', 'x' } },
      jump_next_field_end = { '<Tab>', mode = { 'n', 'v' } },
      jump_prev_field_end = { '<S-Tab>', mode = { 'n', 'v' } },
      jump_next_row = { '<Enter>', mode = { 'n', 'v' } },
      jump_prev_row = { '<S-Enter>', mode = { 'n', 'v' } },
    },
  }
  vim.keymap.set('n', '<leader>cv', '<cmd>CsvViewToggle<CR>', { desc = 'CSV View toggle' })
  -- auto-enable for csv/tsv
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'csv', 'tsv' },
    callback = function() vim.schedule(function() pcall(vim.cmd, 'CsvViewEnable') end) end,
  })
end)

-- dadbod: DB UI toggle <leader>db, completion via blink.cmp source
pcall(function()
  vim.g.db_ui_save_location = vim.fn.stdpath('data') .. '/db_ui'
  vim.g.db_ui_auto_execute_table_helpers = 1
  vim.g.db_ui_use_nerd_fonts = 1
  vim.g.db_ui_show_database_icon = 1

  vim.keymap.set('n', '<leader>db', '<cmd>DBUIToggle<CR>', { desc = 'DB UI toggle' })
  vim.keymap.set('n', '<leader>dB', '<cmd>DBUIAddConnection<CR>', { desc = 'DB Add connection' })
  vim.keymap.set('n', '<leader>dq', function()
    local file = vim.api.nvim_buf_get_name(0)
    if file:match('%.sql$') then
      vim.cmd('DB ' .. vim.fn.getline(1, '$')[1] and '' or '')
      -- fallback: run whole buffer via DB
      vim.cmd(':%DB')
    else
      vim.notify('Open a .sql file first, or use :DB <query>', vim.log.levels.WARN)
    end
  end, { desc = 'DB run buffer' })

  -- completion for sql via dadbod-completion + blink
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'sql', 'mysql', 'plsql', 'psql' },
    callback = function()
      local ok, cmp = pcall(require, 'blink.cmp')
      if ok and cmp.add_source then
        -- blink already handles dadbod-completion via LSP source; ensure filetype has it
        vim.bo.omnifunc = 'vim_dadbod_completion#omni'
      end
      -- keymap for executing paragraph
      vim.keymap.set('n', '<leader>r', 'vip:DB<CR>', { buffer = true, desc = 'DB run paragraph' })
    end,
  })
end)

-- which-key
vim.schedule(function()
  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add({
      { '<leader>cv', desc = 'CSV View toggle' },
      { '<leader>db', desc = 'DB UI toggle' },
      { '<leader>dB', desc = 'DB Add connection' },
      { '<leader>dq', desc = 'DB run' },
    })
  end
end)

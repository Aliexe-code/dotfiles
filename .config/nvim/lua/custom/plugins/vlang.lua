-- V language environment setup (PATH + filetype).
-- Shortcuts were removed on request; V LSP (v-analyzer) is configured in init.lua.

-- Define vsh/vv filetypes to silence vim.lsp unknown filetype warning (v_analyzer uses v,vsh,vv)
pcall(function()
  vim.filetype.add({ extension = { vsh = 'v', vv = 'v' } })
end)

local V_HOME = vim.fn.expand '~/.local/share/v'

-- Ensure Neovim + child processes (LSP, terminals) can find V
do
  local function prepend_path(dir)
    if dir == '' or vim.fn.isdirectory(dir) == 0 then
      return
    end
    local path = vim.env.PATH or ''
    if not path:find(dir, 1, true) then
      vim.env.PATH = dir .. ':' .. path
    end
  end
  prepend_path(V_HOME)
  prepend_path(vim.fn.stdpath 'data' .. '/mason/bin')
  if vim.fn.isdirectory(V_HOME) == 1 then
    vim.env.VROOT = V_HOME
  end
end

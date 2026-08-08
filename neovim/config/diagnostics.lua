local sev = vim.diagnostic.severity

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  float = {
    border = 'rounded',
    source = true,
  },
  signs = {
    text = {
      [sev.ERROR] = 'E',
      [sev.WARN]  = 'W',
      [sev.INFO]  = 'I',
      [sev.HINT]  = 'H',
    },
  },
})

-- Nvim already binds ]d / [d to jump and <C-W>d to show the diagnostic under
-- the cursor; these put the same actions on <leader> so which-key lists them.
vim.keymap.set('n', '<leader>dd', vim.diagnostic.open_float, { desc = 'Show diagnostic' })
vim.keymap.set('n', '<leader>dq', vim.diagnostic.setqflist, { desc = 'Diagnostics to quickfix' })

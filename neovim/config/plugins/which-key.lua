vim.pack.add({ 'https://github.com/folke/which-key.nvim' })

local wk = require('which-key')

wk.setup()

-- Names for the <leader> prefixes, so the popup groups them sensibly
wk.add({
  { '<leader>d', group = 'diagnostics' },
  { '<leader>f', group = 'find' },
  { '<leader>h', group = 'hunks' },
  { '<leader>t', group = 'toggles' },
})

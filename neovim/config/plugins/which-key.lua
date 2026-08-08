vim.pack.add({ 'https://github.com/folke/which-key.nvim' })

local wk = require('which-key')

wk.setup()

-- Names for the gitsigns prefixes, so the popup groups them sensibly
wk.add({
  { '<leader>h', group = 'hunks' },
  { '<leader>t', group = 'toggles' },
})

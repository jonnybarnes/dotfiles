vim.pack.add({ 'https://github.com/ibhagwan/fzf-lua' })

local fzf = require('fzf-lua')

fzf.setup()

local function map(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

map('<leader>ff', fzf.files, 'Find files')
map('<leader>fg', fzf.live_grep, 'Grep project')
map('<leader>fb', fzf.buffers, 'Switch buffer')
map('<leader>fw', fzf.grep_cword, 'Grep word under cursor')
map('<leader>fh', fzf.helptags, 'Search help')

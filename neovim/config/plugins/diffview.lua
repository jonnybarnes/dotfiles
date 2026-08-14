vim.pack.add({ 'https://github.com/sindrets/diffview.nvim' })

require('diffview').setup()

local function map(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

map('<leader>gd', '<Cmd>DiffviewOpen<CR>', 'Diff against index')
map('<leader>gc', '<Cmd>DiffviewClose<CR>', 'Close diff view')
map('<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', 'File history')
map('<leader>gH', '<Cmd>DiffviewFileHistory<CR>', 'Branch history')

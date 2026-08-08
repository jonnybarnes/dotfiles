-- Must be set before netrw loads, which happens after init.lua is sourced.
-- nvim-tree takes over directory buffers, so `nvim .` opens the tree.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.pack.add({ 'https://github.com/nvim-tree/nvim-tree.lua' })

require('nvim-tree').setup({
  view = { side = 'right' },
})

vim.keymap.set('n', '<leader>e', '<Cmd>NvimTreeToggle<CR>', { desc = 'Toggle file tree' })

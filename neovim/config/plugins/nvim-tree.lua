-- Must be set before netrw loads, which happens after init.lua is sourced.
-- nvim-tree takes over directory buffers, so `nvim .` opens the tree.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.pack.add({ 'https://github.com/nvim-tree/nvim-tree.lua' })

require('nvim-tree').setup({
  view = { side = 'right' },
  -- nvim-tree hides gitignored files by default; show them, so things like
  -- .env are visible. `I` in the tree toggles this back off per session.
  filters = { git_ignored = false },
  -- Reveal the current buffer in the tree on BufEnter, expanding folders to
  -- get to it, so opening a file from fzf-lua moves the tree with you.
  update_focused_file = { enable = true },
})

vim.keymap.set('n', '<leader>e', '<Cmd>NvimTreeToggle<CR>', { desc = 'Toggle file tree' })

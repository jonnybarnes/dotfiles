--[[
My NeoVim configuration
--]]

-- Plugins
vim.pack.add({"https://github.com/lewis6991/gitsigns.nvim"})

-- nvim-tree recommends disabling netrw (vim’s file explorer)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.pack.add({"https://github.com/nvim-tree/nvim-tree.lua"})
require("nvim-tree").setup()

-- Editor options
-- show line numbers
vim.opt.number = true

-- set spelling to British English
vim.opt.spelllang = 'en_gb'
vim.opt.spell = true

-- 24-bit colour support
vim.opt.termguicolors = true

-- LSP/PHP setup
vim.lsp.enable('phpactor')

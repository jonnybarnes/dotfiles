--[[
My NeoVim configuration
--]]

-- Plugins
-- nvim-tree recommends disabling netrw (vim’s file explorer)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
--require("nvim-tree").setup()

--require('gitsigns').setup()

-- Editor options
-- show line numbers
vim.opt.number = true

-- set spelling to British English
vim.opt.spelllang = 'en_gb'
vim.opt.spell = true

-- 24-bit colour support
vim.opt.termguicolors = true

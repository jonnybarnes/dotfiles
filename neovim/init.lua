--[[
My NeoVim configuration
--]]

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Plugins
require('nvim-web-devicons').setup()
-- require('oil').setup()
require('nvim-tree').setup()
require('gitsigns').setup()
require('lspconfig').phpactor.setup({})

-- Editor options
vim.wo.number = true

vim.opt.spelllang = 'en_gb'
vim.opt.spell = true

-- 24-bit colour support
vim.opt.termguicolors = true

--[[
My NeoVim configuration
--]]

require('nvim-web-devicons').setup()
require('oil').setup()
require('gitsigns').setup()
require('lspconfig').phpactor.setup({})

-- Editor options
vim.wo.number = true

vim.opt.spelllang = 'en_gb'
vim.opt.spell = true

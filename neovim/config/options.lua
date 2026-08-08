-- Set before any plugin defines a <leader> mapping
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.o.autocomplete = true
vim.o.pumborder = 'rounded'
vim.o.pummaxwidth = 40
vim.o.completeopt = 'menu,menuone,noinsert,nearest'
vim.o.number = true
-- Always shown, so git/diagnostic signs don't shift the text around
vim.o.signcolumn = 'yes'
vim.o.spelllang = 'en_gb'
vim.o.spell = true
vim.o.termguicolors = true

-- Hard-wrap prose at 80, the markdownlint/prettier default. +1 puts the guide
-- just past the limit, so a line touching it is still fine.
vim.bo.textwidth = 80
vim.wo.colorcolumn = '+1'

vim.pack.add({ { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' } })

require('catppuccin').setup({
  -- Follow 'background', which the TUI sets from the terminal on startup
  flavour = 'auto',
  background = {
    light = 'latte',
    dark = 'macchiato',
  },
})

vim.cmd.colorscheme('catppuccin')

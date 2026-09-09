vim.pack.add({ { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' } })

require('catppuccin').setup({
  -- Follow 'background', which the TUI sets from the terminal on startup
  flavour = 'auto',
  background = {
    light = 'latte',
    dark = 'macchiato',
  },
  custom_highlights = function(colors)
    return {
      -- CursorLine sits a shade away from the tree's own mantle background,
      -- so the file you're viewing is invisible in nvim-tree. Give the tree
      -- a band you can actually pick out.
      NvimTreeCursorLine = { bg = colors.surface1 },
    }
  end,
})

vim.cmd.colorscheme('catppuccin')

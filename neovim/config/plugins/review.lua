-- Typed review comments on top of codediff, exported as markdown for an agent.
-- nui.nvim draws the comment popup.
vim.pack.add({
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/georgeguimaraes/review.nvim',
})

require('review').setup({
  -- base = nil: origin's cached HEAD, then main or master. The codediff
  -- mappings (<leader>gm, <leader>gR) keep the fuller remote fallback for
  -- repos where origin has no cached HEAD.
  branch = { base = nil },
  export = {
    -- Clipboard is the whole loop: q exports, then paste into Claude Code.
    clipboard = true,
  },
})

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

map('n', '<leader>rr', '<Cmd>Review<CR>', 'Review working tree')
map('n', '<leader>rb', '<Cmd>Review branch<CR>', 'Review branch')
map('n', '<leader>rc', '<Cmd>Review commits<CR>', 'Review commits')
map({ 'n', 'v' }, '<leader>rn', '<Cmd>Review note<CR>', 'Review note')

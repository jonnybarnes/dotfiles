vim.pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' })

local gitsigns = require('gitsigns')

gitsigns.setup()

-- Mapped globally rather than from on_attach. Gitsigns attaches asynchronously,
-- after which-key has already built its keymap tree for the buffer, and
-- which-key only rebuilds that on BufReadPost/BufNew/LspAttach - so
-- buffer-local maps added later never show up in its popup. The gitsigns API
-- no-ops in buffers it hasn't attached to, so global maps are safe.
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

-- Navigation, falling back to vim's own diff motions in diff mode
map('n', ']c', function()
  if vim.wo.diff then
    vim.cmd.normal({ ']c', bang = true })
  else
    gitsigns.nav_hunk('next')
  end
end, 'Next git hunk')

map('n', '[c', function()
  if vim.wo.diff then
    vim.cmd.normal({ '[c', bang = true })
  else
    gitsigns.nav_hunk('prev')
  end
end, 'Previous git hunk')

-- Actions
map('n', '<leader>hs', gitsigns.stage_hunk, 'Stage hunk')
map('n', '<leader>hr', gitsigns.reset_hunk, 'Reset hunk')

map('v', '<leader>hs', function()
  gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
end, 'Stage selected hunk')

map('v', '<leader>hr', function()
  gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
end, 'Reset selected hunk')

map('n', '<leader>hS', gitsigns.stage_buffer, 'Stage buffer')
map('n', '<leader>hR', gitsigns.reset_buffer, 'Reset buffer')
map('n', '<leader>hp', gitsigns.preview_hunk, 'Preview hunk')
map('n', '<leader>hd', gitsigns.diffthis, 'Diff against index')

map('n', '<leader>hb', function()
  gitsigns.blame_line({ full = true })
end, 'Blame line')

map('n', '<leader>hq', gitsigns.setqflist, 'Hunks to quickfix')

-- Toggles
map('n', '<leader>tb', gitsigns.toggle_current_line_blame, 'Toggle line blame')
map('n', '<leader>td', gitsigns.toggle_deleted, 'Toggle deleted lines')

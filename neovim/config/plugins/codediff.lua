vim.pack.add({ 'https://github.com/esmuellert/codediff.nvim' })

require('codediff').setup({
  keymaps = {
    -- q closes the diff tab from inside it; <leader>gc is here too so the
    -- same key that opened things from the g/diff group also shuts them.
    view = { quit = { 'q', '<leader>gc' } },
  },
})

local function map(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

map('<leader>gd', '<Cmd>CodeDiff<CR>', 'Diff working tree')
map('<leader>gh', '<Cmd>CodeDiff history %<CR>', 'File history')
map('<leader>gH', '<Cmd>CodeDiff history<CR>', 'Branch history')

-- The base branch name varies per repo (main, master, develop, ...), so ask
-- the first remote's HEAD what it is rather than hardcoding one.
local function default_branch()
  local remote = vim.fn.systemlist('git remote')[1]
  if not remote or remote == '' then
    return ''
  end
  local ref = vim.fn.systemlist('git symbolic-ref refs/remotes/' .. remote .. '/HEAD')[1]
  if not ref or ref == '' then
    return ''
  end
  return ref:gsub('^refs/remotes/' .. remote .. '/', '')
end

map('<leader>gm', function()
  vim.ui.input({ prompt = 'Diff against: ', default = default_branch() }, function(rev)
    if rev and rev ~= '' then
      -- rev...HEAD is merge-base semantics: what this branch added, not what
      -- the base branch has moved on to since.
      vim.cmd('CodeDiff ' .. rev .. '...HEAD')
    end
  end)
end, 'Diff against branch')

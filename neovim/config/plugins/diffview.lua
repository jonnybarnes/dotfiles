vim.pack.add({ 'https://github.com/sindrets/diffview.nvim' })

require('diffview').setup()

local function map(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

map('<leader>gd', '<Cmd>DiffviewOpen<CR>', 'Diff against index')
map('<leader>gc', '<Cmd>DiffviewClose<CR>', 'Close diff view')
map('<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', 'File history')
map('<leader>gH', '<Cmd>DiffviewFileHistory<CR>', 'Branch history')

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
      vim.cmd('DiffviewOpen ' .. rev .. '...HEAD')
    end
  end)
end, 'Diff against branch')

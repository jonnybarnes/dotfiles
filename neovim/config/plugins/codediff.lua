vim.pack.add({ 'https://github.com/esmuellert/codediff.nvim' })

require('codediff').setup({
  diff = {
    -- Inline, GitHub-style: side-by-side is unreadable at laptop width. `t`
    -- toggles back per session, `gc` toggles the folding.
    layout = 'inline',
    compact = true,
    gutter_signs = true,
  },
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

-- A remote's cached HEAD, or nil if it has none. Kept current by
-- remote.origin.followRemoteHEAD in the gitconfig and by `git sync`; without
-- those this is whatever the default branch was at clone time.
local function remote_head(remote)
  local prefix = 'refs/remotes/' .. remote .. '/'
  -- --quiet so a remote with no cached HEAD stays silent rather than having its
  -- error text come back as the branch name.
  local ref = vim.fn.systemlist('git symbolic-ref --quiet ' .. prefix .. 'HEAD')[1]
  if not ref or ref:sub(1, #prefix) ~= prefix then
    return nil
  end
  return ref:sub(#prefix + 1)
end

-- The base branch name varies per repo (main, master, totara-20, ...), so ask a
-- remote rather than hardcoding one. origin first: in the fork workflow that is
-- my fork, and `git sync` keeps its default branch level with upstream's. Only
-- then upstream, then whatever remotes exist - `git remote` sorts them
-- alphabetically, so first-available on its own can hand back a colleague's fork.
local function default_branch()
  local candidates = { 'origin', 'upstream' }
  vim.list_extend(candidates, vim.fn.systemlist('git remote'))
  for _, remote in ipairs(candidates) do
    local branch = remote_head(remote)
    if branch then
      return branch
    end
  end
  return ''
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

-- A commit-ish under the cursor, or nil. Lets <leader>gr be pressed straight on
-- a sha pasted in a commit message, a code comment or a fugitive/log buffer.
-- ^{commit} so a tag or tree does not pass as something diffable, and --quiet
-- so a cword like 'function' fails silently instead of shouting.
local function commit_under_cursor()
  local cword = vim.fn.expand('<cword>')
  if cword == '' then
    return nil
  end
  vim.fn.systemlist('git rev-parse --verify --quiet ' .. vim.fn.shellescape(cword) .. '^{commit}')
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return cword
end

map('<leader>gr', function()
  local default = commit_under_cursor() or 'HEAD'
  vim.ui.input({ prompt = 'Review commit: ', default = default }, function(rev)
    if rev and rev ~= '' then
      -- rev^ rev, not `history`, so the explorer opens on that one commit's
      -- files. A merge commit diffs against its first parent, as git does.
      vim.cmd('CodeDiff ' .. rev .. '^ ' .. rev)
    end
  end)
end, 'Review a commit')

map('<leader>gR', function()
  vim.ui.input({ prompt = 'Commits since: ', default = default_branch() }, function(rev)
    if rev and rev ~= '' then
      -- Commit-by-commit rather than squashed: the history panel lists each
      -- commit the branch is missing, oldest first, so they read in the order
      -- they were made.
      vim.cmd('CodeDiff history ' .. rev .. '..HEAD --reverse')
    end
  end)
end, 'Review commits since branch')

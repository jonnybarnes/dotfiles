# neovim

Requires Neovim **0.12+**. Several options used here (`autocomplete`,
`pumborder`, `pummaxwidth`, and `nearest` in `completeopt`) only exist from 0.12,
and plugins are managed with `vim.pack`, which landed in 0.12 too.

Day-to-day keymaps are not listed here — press `<Space>` and pause, and
which-key shows what is available. This file covers the things that are *not*
discoverable that way.

## Layout

`bootstrap.sh` symlinks the pieces individually rather than linking the whole
directory, because `~/.config/nvim` also holds state Neovim writes itself:

| repo | symlinked to |
| --- | --- |
| `init.lua` | `~/.config/nvim/init.lua` |
| `config/` | `~/.config/nvim/lua/config` |
| `lsp/phpactor.lua` | `~/.config/nvim/lsp/phpactor.lua` |
| `nvim-pack-lock.json` | `~/.config/nvim/nvim-pack-lock.json` |

`config/` is linked in as `lua/config` so everything is reachable as
`require('config.…')`, which is what `init.lua` and `config/init.lua` do.

## Plugins

Managed by `vim.pack`, so there is no plugin manager to bootstrap. Each plugin
gets a file under `config/plugins/` that calls `vim.pack.add()` and then
configures itself, and `config/plugins/init.lua` requires them in turn.

Update with `:lua vim.pack.update()`. Versions are pinned in
`nvim-pack-lock.json`, which is tracked — commit it after an update so the other
machine gets the same set.

> [!NOTE]
> nvim-web-devicons needs a Nerd Font in the terminal or the icons render as
> tofu. `brew.sh` installs one for ghostty.

## Defaults worth knowing

- **Spell checking is on globally**, `en_gb` — in every buffer, code included,
  not just prose filetypes.
- **Autocompletion is on** via Neovim's own `vim.o.autocomplete`, with a rounded
  popup capped at 40 columns. No completion plugin is involved.
- **The sign column is always shown**, so git and diagnostic signs appearing do
  not shift the text sideways.
- **netrw is disabled** and nvim-tree takes over directory buffers, so `nvim .`
  opens the tree rather than netrw. The tree opens on the **right**.
- **The tree shows gitignored files**, unlike nvim-tree's default — so `.env` is
  visible, at the cost of `vendor/`, `node_modules/` and friends also showing.
  `I` in the tree hides them again for the session.
- **The tree follows the current buffer**, expanding folders to reveal whatever
  you open — including files opened from fzf-lua. It does not change the tree
  root to do so, so opening a file from outside the root won't reveal it.
- **Diagnostic signs are letters** (`E` `W` `I` `H`) rather than icons, and do
  not update while you are in insert mode.

## PHP / LSP

`lsp/phpactor.lua` is the only language server configured, enabled from
`config/lsp.lua`. It expects `phpactor` on `PATH` (`brew.sh` does not install
it — it is a Composer global install).

It sets `workspace_required`, so it only attaches inside a project with one of
`.git`, `composer.json`, `.phpactor.json` or `.phpactor.yml` — a loose `.php`
file opened on its own gets no LSP, which is intentional rather than broken.

phpactor's bundled phpstan and psalm integrations are both disabled, so
diagnostics come from phpactor itself. Run those tools separately if you want
them.

> [!IMPORTANT]
> gitsigns keymaps are set globally, not from `on_attach`. Gitsigns attaches
> asynchronously, after which-key has already built its keymap tree for the
> buffer, and which-key only rebuilds on `BufReadPost`/`BufNew`/`LspAttach` — so
> buffer-local maps added later never appear in the popup. The gitsigns API
> no-ops in buffers it has not attached to, which is what makes global maps safe
> here. Don't “fix” this by moving them into `on_attach`.

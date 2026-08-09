# dotfiles

Here’s my dotfiles, inspired by people like Mathias. See his dotfiles at
[`https://github.com/mathias/dotfiles`](https://github.com/mathias/dotfiles).

The idea I’m currently going down is to create a symlink from `$HOME` to this
directory. There is one exception to this, the `.gitconfig` file. I don’t want
actual commiter details committed into this repo, and they differ per machine
anyway — this Mac signs with my work address, the iMac with my personal one.

So identity and signing live in an untracked `$HOME/.gitconfig.local`, which the
tracked `gitconfig` pulls in with an `[include]` as its **last** directive. Last
matters: git applies config in file order, so anything after the include would
override it.

`$HOME/.gitconfig` is copied rather than symlinked, so that an ad-hoc
`git config --global` writes into `$HOME` instead of dirtying this repo. The
trade-off is that `git pull` alone does not update it — re-run `./bootstrap.sh`,
or `cp gitconfig ~/.gitconfig`, after changing the tracked copy.

## Usage

First clone the repo.

Run `./bootstrap.sh`, this will create all the necessary symlinks, then source
`.zshrc`.

> [!WARNING]
> This is a **destructive** process, so backup your dotfiles first.

As mentioned above, git identity lives in an untracked `$HOME/.gitconfig.local`.
`bootstrap.sh` seeds it from `gitconfig.local.template` if it does not already
exist, and never overwrites an existing one. Fill it in:

```
[user]
    name = Jonny Barnes
    email = jonny@jonnybarnes.uk
    signingkey = ssh-ed25519 AAAA...

[commit]
    gpgsign = true

[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
```

Do not skip this. Git will not prompt you — with no identity it quietly derives
one from your username and hostname, warns once, and signs nothing.

`$HOME/.extra` is a separate untracked file for other machine-local environment
variables, sourced from `.zshrc`. Keep git out of it:

> [!IMPORTANT]
> Never put `git config --global` in `.extra`. It is re-sourced on every
> `SIGUSR1`, so with several tmux panes the concurrent writes race on
> `~/.gitconfig.lock` and spew `error: could not lock config file`. Put git
> settings in `.gitconfig.local` instead.

## Light and dark mode

Most of this is now handled natively and needs no configuration:

- **ghostty** follows the system appearance itself via
  `theme = light:tangere-light.conf,dark:tangere-dark.conf`.
- **tmux** 3.6+ learns the terminal’s theme over OSC 2031 and exposes it as
  `#{client_theme}`.
- **bat** picks a theme per invocation from `BAT_THEME_LIGHT` / `BAT_THEME_DARK`.
- **delta** and **nvim** detect the terminal background themselves.

The tmux status bar needs help, because its colours are set explicitly. They live
in `tmux-light.conf` and `tmux-dark.conf` — the same layout, with each colour
taken from the matching tangere palette index — and `tmux` sources one of them
from three hooks:

- `client-light-theme` / `client-dark-theme` react to a change,
- `client-attached` picks the right one for a client that attaches mid-way, since
  the two above only fire on a change.

Because this keys off the terminal's reported theme rather than a schedule, it
behaves identically whether the change came from Auto at sunrise/sunset or from
toggling Light/Dark by hand — nothing in the chain knows why it changed.

> [!NOTE]
> A running nvim will not follow a live change: the docs are explicit that the
> TUI sets `background` *on startup* if it can detect it. New instances are
> fine — verified, a fresh nvim in light mode reports `background=light` — but
> existing ones need `:set background=light` or a restart.

Verified in light mode: the status bar switches in the same second the hook
fires, a fresh nvim detects `light`, and delta resolves its light default
(`syntax-theme = GitHub`, against `Monokai Extended` on dark).

> [!TIP]
> When adding these hooks to an *already running* tmux server, detach and
> reattach. tmux enables the terminal’s theme-reporting mode when a client
> attaches, so a client that predates the hooks never gets asked to report
> changes — `#{client_theme}` still reads correctly, because that is answered by
> a direct query, but no hook fires until the client reattaches.

> [!NOTE]
> This previously used [`dark-mode-notify`](https://github.com/bouk/dark-mode-notify)
> as a `launchd` agent that ran `pkill -usr1 zsh` on every appearance change.
> That has been removed. It could never have worked: re-sourcing `.zshrc` runs
> inside each *shell*, but the status bar belongs to the tmux *server* and
> colours to a running nvim, so it could not retheme either. The one variable it
> set was read by nothing. Meanwhile it fired on every unlock, re-running
> `.zshrc` in every pane. Don’t bring it back.


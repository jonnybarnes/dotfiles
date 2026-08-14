# add C-a as primary prefix, keep C-b as secondary
set-option -g prefix C-a
set-option -g prefix2 C-b
bind-key C-a send-prefix

# start with window 1 (instead of 0)
set -g base-index 1
# also start with 1 for window panes
setw -g pane-base-index 1

# renumber windows sequentially after closing any of them
set -g renumber-windows on

# don't detach when closing a window if other windows remain
set -g detach-on-destroy off

# prompt for a name and create a session in one step, instead of
# `<prefix> :` then `new -s name`
bind-key S command-prompt -p "New session name:" "new-session -s '%%'"

# reload config file (change file location to your the tmux.conf you want to use)
unbind r
bind r source-file ~/.tmux.conf

# Enable mouse mode (tmux 2.1 and above)
set -g mouse on

# Track focus events
set-option -g focus-events on

# don't rename windows automatically
set-option -g allow-rename off

# Set terminal
set -g default-terminal "$TERM"

# Allow OSC 8 links
set -ga terminal-features "*:hyperlinks"

# Set status bar length
set -g status-left-length 40
set -g status-right-length 60

# Center the window list
set -g status-justify centre

# Status bar colours live in ~/.tmux-light.conf and ~/.tmux-dark.conf. tmux
# learns the terminal's theme over OSC 2031, so this reacts to the appearance
# change itself, whether that came from Auto at sunrise/sunset or a manual
# toggle, since nothing here knows why it changed.
set-hook -g client-light-theme 'source-file ~/.tmux-light.conf'
set-hook -g client-dark-theme 'source-file ~/.tmux-dark.conf'

# Those hooks only fire on a change, so also pick the right palette whenever a
# client attaches. Sourcing is idempotent, so the overlap is harmless.
set-hook -g client-attached 'if -F "#{==:#{client_theme},light}" "source-file ~/.tmux-light.conf" "source-file ~/.tmux-dark.conf"'

# Default before any client has attached and reported a theme. This also
# runs on manual reload (`r` below), so check the invoking client's theme
# rather than always falling back to dark and clobbering a light session.
if -F "#{==:#{client_theme},light}" "source-file ~/.tmux-light.conf" "source-file ~/.tmux-dark.conf"

# remap prefix from 'C-b' to 'C-a'
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# start with window 1 (instead of 0)
set -g base-index 1

# renumber windows sequentially after closing any of them
set -g renumber-windows on

# reload config file (change file location to your the tmux.conf you want to use)
bind r source-file ~/.tmux.conf

# Enable mouse mode (tmux 2.1 and above)
set -g mouse on

# don't rename windows automatically
set-option -g allow-rename off

# Get 256 colour support
set -g default-terminal "screen-256color"
# tell Tmux that outside terminal supports true color
set -as terminal-features ",xterm-256color:RGB"

# Tweak status bar styles
set -g status-style bg='color91',fg='color7'

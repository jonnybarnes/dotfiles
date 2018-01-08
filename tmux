# remap prefix from 'C-b' to 'C-a'
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# start with window 1 (instead of 0)
set -g base-index 1

# reload config file (change file location to your the tmux.conf you want to use)
bind r source-file ~/.tmux.conf

# Enable mouse mode (tmux 2.1 and above)
set -g mouse on

# don't rename windows automatically
set-option -g allow-rename off

# Get 256 colour support
set -g default-terminal "screen-256color"

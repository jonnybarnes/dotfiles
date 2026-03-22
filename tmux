# remap prefix from 'C-b' to 'C-a'
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# start with window 1 (instead of 0)
set -g base-index 1
# also start with 1 for window panes
setw -g pane-base-index 1

# renumber windows sequentially after closing any of them
set -g renumber-windows on

# reload config file (change file location to your the tmux.conf you want to use)
unbind r
bind r source-file ~/.tmux.conf

# Enable mouse mode (tmux 2.1 and above)
set -g mouse on

# don't rename windows automatically
set-option -g allow-rename off

# Allow OSC 8 links
set -ga terminal-features "*:hyperlinks"

# Get 256 colour support
set -g default-terminal "screen-256color"
# tell Tmux that outside terminal supports true color
set -as terminal-features ",xterm-256color:RGB"

# Tweak status bar styles
set -g status-style bg=default,fg='#fdfdd9'

# Set status bar length
set -g status-left-length 40
set -g status-right-length 60

# Center the window list
set -g status-justify centre

# Left side: session name with blue accent
set -g status-left "#[fg=#1a2938,bg=#8fb4cd,bold]  #S #[fg=#8fb4cd,bg=default]\ue0b0"

# Right side: multi-segment with transitions
set -g status-right "#[fg=#6dafb5,bg=default]\ue0b2#[fg=#1a2938,bg=#6dafb5] %H:%M #[fg=#bb98d9,bg=#6dafb5]\ue0b2#[fg=#1a2938,bg=#bb98d9] %d-%b "

# Inactive windows (no powerline symbols)
setw -g window-status-format "#[fg=#2f4656,bg=default] #I #W "

# Active window (cyan highlight, no powerline)
setw -g window-status-current-format "#[fg=#1a2938,bg=#6dafb5,bold] #I #W "

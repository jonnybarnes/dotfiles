-- Rex config, migrated from tmux, Ghostty and iTerm2.

-- tmux (~/.tmux.conf), prefix ctrl+a
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" }) -- :4 bind-key C-a send-prefix
rex.bind("ctrl+a>r", "client.config.reload")                   -- :23 bind r source-file ~/.tmux.conf

-- iTerm2 (GlobalKeyMap)
rex.bind("shift+enter", "pane.send_key", { key = "ctrl+j" })   -- 0xd-0x20000: send text "\n"

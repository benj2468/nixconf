{ pkgs, ... }: {
  programs.tmux = {
    enable = true; # install tmux and manage ~/.config/tmux/tmux.conf via home-manager

    terminal = "tmux-256color"; # the TERM value inside tmux; advertises 256-colour support to programs

    # C-a is far easier to reach than the default C-b.
    prefix = "C-a"; # the "leader" key: press Ctrl+a before any tmux command below

    keyMode = "vi"; # use vi-style keys (h/j/k/l, v, y, ...) in copy mode and the status prompt
    mouse = true; # allow the mouse to select panes, resize splits, scroll, and click windows
    baseIndex = 1; # number windows starting at 1 instead of 0 (matches the keyboard layout)
    escapeTime = 0; # no wait after pressing Escape, so Esc feels instant in nvim
    historyLimit = 100000; # keep 100k lines of scrollback per pane
    focusEvents = true; # forward terminal focus in/out to programs, so nvim autoread/autosave work

    plugins = with pkgs.tmuxPlugins; [
      sensible # a set of widely-agreed-upon default settings (safe baseline tweaks)
      vim-tmux-navigator # C-h/j/k/l across nvim splits and tmux panes
      yank # copy to the system clipboard from copy mode
      {
        plugin = extrakto; # prefix+e: label every path/url/word on screen, type the label to copy/paste it
        extraConfig = ''
          set -g @extrakto_key 'e' # trigger extrakto with prefix+e (default is prefix+Tab, which we use for last-window)
          set -g @extrakto_split_direction 'p' # show extrakto in a popup rather than splitting the pane
        '';
      }
      {
        plugin = resurrect; # save/restore whole tmux sessions (windows, panes, layout)
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session' # also restore nvim if it was running via its session file
          set -g @resurrect-capture-pane-contents 'on' # restore the visible text that was in each pane
        '';
      }
      {
        plugin = continuum; # automate resurrect: save on a timer and restore on tmux start
        extraConfig = ''
          set -g @continuum-restore 'on' # automatically restore the last saved session when tmux starts
          set -g @continuum-save-interval '10' # auto-save every 10 minutes
        '';
      }
    ];

    extraConfig = ''
      set -g status on # show the status bar at the bottom of the screen

      # True colour + undercurl passthrough for nvim.
      set -ga terminal-overrides ",*256col*:Tc" # tell tmux the terminal supports 24-bit "true" colour
      set -ga terminal-overrides ",*:U8=0" # fix wide/unicode glyph handling in some terminals

      # Windows and panes count from 1; keep them contiguous.
      setw -g pane-base-index 1 # number panes starting at 1 (baseIndex above only covers windows)
      set -g renumber-windows on # when a window closes, renumber the rest so there are no gaps
      setw -g aggressive-resize on # a pane uses the full space of the client viewing it, not the smallest attached client

      # Clipboard: make copy work everywhere, including over SSH.
      set -g set-clipboard on # let programs (and yank) write the system clipboard via the OSC 52 escape sequence
      set -g allow-passthrough on # forward special escape sequences through tmux (OSC 52 clipboard, inline images)

      # ------------------------------------------------------------------
      # Catppuccin status bar (options must be set before the plugin runs).
      # ------------------------------------------------------------------
      set -g @catppuccin_window_status_style "rounded" # give window tabs rounded end-caps
      set -g @catppuccin_window_number_position "right" # put the window number on the right of each tab
      set -g @catppuccin_window_default_fill "number" # colour-fill the number area on inactive windows
      set -g @catppuccin_window_current_fill "number" # colour-fill the number area on the active window
      set -g @catppuccin_window_default_text " #W" # inactive tab shows a space + the window name (#W)
      set -g @catppuccin_window_current_text " #W" # active tab shows a space + the window name (#W)
      set -g status-right-length 100 # allow up to 100 columns of content on the right side
      set -g status-left-length 100 # allow up to 100 columns of content on the left side
      set -g status-left "" # empty left side (no session name block on the left)
      set -g status-right "#{E:@catppuccin_status_session}" # right side starts with the session module
      set -ag status-right "#{E:@catppuccin_status_host}" # append the hostname module (-a = append)
      set -ag status-right "#{E:@catppuccin_status_date_time}" # append the date/time module

      # ------------------------------------------------------------------
      # Key bindings
      # ------------------------------------------------------------------

      # Reload config on the fly.
      bind r source-file ~/.config/tmux/tmux.conf \; display "tmux.conf reloaded" # prefix+r re-reads config and flashes a message

      # Intuitive splits that keep the current working directory.
      bind "|" split-window -h -c "#{pane_current_path}" # prefix+| splits left/right (-h), new pane keeps cwd
      bind "\\" split-window -fh -c "#{pane_current_path}" # prefix+\ splits full-height left/right across the whole window
      bind "-" split-window -v -c "#{pane_current_path}" # prefix+- splits top/bottom (-v), new pane keeps cwd
      bind "_" split-window -fv -c "#{pane_current_path}" # prefix+_ splits full-width top/bottom across the whole window
      bind c new-window -c "#{pane_current_path}" # prefix+c opens a new window in the current pane's directory
      unbind '"' # remove the default horizontal-split binding (we use - instead)
      unbind % # remove the default vertical-split binding (we use | instead)

      # Repeatable pane resizing with prefix + H/J/K/L.
      bind -r H resize-pane -L 5 # grow pane leftward by 5 cells (-r lets you repeat without re-pressing prefix)
      bind -r J resize-pane -D 5 # grow pane downward by 5 cells
      bind -r K resize-pane -U 5 # grow pane upward by 5 cells
      bind -r L resize-pane -R 5 # grow pane rightward by 5 cells

      # Quick window switching.
      bind -r C-h previous-window # prefix then Ctrl+h moves to the previous window (repeatable)
      bind -r C-l next-window # prefix then Ctrl+l moves to the next window (repeatable)
      bind Tab last-window # prefix+Tab jumps back to the previously active window

      # vi-style copy mode with system-clipboard yank.
      bind Enter copy-mode # prefix+Enter enters scrollback/copy mode
      bind -T copy-mode-vi v send -X begin-selection # in copy mode, v starts a selection (like visual mode)
      bind -T copy-mode-vi C-v send -X rectangle-toggle # Ctrl+v toggles a block/rectangular selection
      bind -T copy-mode-vi y send -X copy-selection-and-cancel # y copies the selection (yank) and exits copy mode
      bind -T copy-mode-vi Escape send -X cancel # Escape leaves copy mode without copying

      # ------------------------------------------------------------------
      # Popups and power tools
      # ------------------------------------------------------------------

      # prefix+g: lazygit floating over the current pane's repo (-E closes the popup when it exits).
      bind g display-popup -E -w 90% -h 90% -d "#{pane_current_path}" "lazygit"

      # prefix+o: a throwaway floating shell in the current directory; run a command, then exit to dismiss.
      bind o display-popup -E -w 80% -h 75% -d "#{pane_current_path}"

      # prefix+s: fuzzy-switch sessions in a popup (replaces the default tree-picker with fzf).
      bind s display-popup -E -w 40% -h 40% -T " switch session " \
        "tmux list-sessions -F '#{session_name}' | fzf --reverse --no-multi | xargs -r tmux switch-client -t"

      # prefix+m: toggle synchronize-panes, so keystrokes go to every pane at once (e.g. same command on many servers).
      bind m set-window-option synchronize-panes \; display "synchronize-panes #{?pane_synchronized,on,off}"

      # Point SSH_AUTH_SOCK to a fixed location for tmux.
      set-option -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY" # refresh these env vars from new client attachments
      set-environment -g SSH_AUTH_SOCK "$HOME/.ssh/ssh_auth_sock" # use a stable agent socket so ssh-agent keeps working after reattaching
    '';
  };
}

{ ... }: {
  programs.tmux = {
    enable = true;

    terminal = "tmux-256color";

    extraConfig = ''
      set -g status on
      set -g mouse on

      # Catppuccin options
      set -g @catppuccin_host 'on'
      set -g @catppuccin_window_tabs_enabled 'on'
    '';
  };
}

{ ... }: {
  programs.tmux = {
    enable = true;

    terminal = "tmux-256color";

    extraConfig = ''
      set -g status on
      set -g mouse on
    '';
  };
}

{ ... }: {
  programs.tmux = {
    enable = true;

    terminal = "tmux-256color";

    extraConfig = ''
      set -g status on
      set -g mouse on


      # Point SSH_AUTH_SOCK to a fixed location for tmux
      set-option -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"
      set-environment -g SSH_AUTH_SOCK "$HOME/.ssh/ssh_auth_sock"
    '';
  };
}

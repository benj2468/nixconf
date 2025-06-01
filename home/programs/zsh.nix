{ ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      nix-switch = "sudo nixos-rebuild switch";
      home-switch = "home-manager switch --flake /etc/nixos#$(whoami)@$(hostname)";
      jfu = "journalctl -fu";
    };

    initContent = ''
      ZSH_TMUX_AUTOSTART=true
      ZSH_TMUX_FIXTERM=false
      ZSH_TMUX_CONFIG=$HOME/.config/tmux/tmux.conf
    '';
  };
}

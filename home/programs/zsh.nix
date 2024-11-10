{pkgs, ...}: {

  home.packages = [ pkgs.zsh ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = ["git" "thefuck" "tmux"];
      theme = "robbyrussell";
    };

    initExtra = ''
      ZSH_TMUX_AUTOSTART=true
      ZSH_TMUX_FIXTERM=false
      ZSH_TMUX_CONFIG=$HOME/.config/tmux/tmux.conf
    '';
  };
}

{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      ZSH_TMUX_AUTOSTART=true
      ZSH_TMUX_FIXTERM=false
      ZSH_TMUX_CONFIG=$HOME/.config/tmux/tmux.conf
    '';

    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
  };
}

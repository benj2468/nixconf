{ pkgs, ... }: {
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    completionInit = "autoload -U compinit && compinit -u"; # The -u flag ignores insecure directories

    initContent = ''
      ZSH_TMUX_AUTOSTART=true
      ZSH_TMUX_FIXTERM=false
      ZSH_TMUX_CONFIG=$HOME/.config/tmux/tmux.conf

      # Update SSH auth socket symlink
      if [ "$SSH_AUTH_SOCK" ]; then
        ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
      fi
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

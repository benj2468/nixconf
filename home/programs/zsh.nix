{ lib, pkgs, ... }: {
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

    initContent = lib.mkMerge [
      ''
        ZSH_TMUX_AUTOSTART=true
        ZSH_TMUX_FIXTERM=false
        ZSH_TMUX_CONFIG=$HOME/.config/tmux/tmux.conf

        # Update SSH auth socket symlink
        if [ "$SSH_AUTH_SOCK" ]; then
          ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
        fi
      ''
      # Machine-local, unmanaged settings (secrets, work env) that must stay out of the store.
      # Sourced last so they can override anything above.
      (lib.mkOrder 2000 ''
        [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
      '')
    ];

    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
  };
}

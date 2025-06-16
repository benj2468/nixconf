{ pkgs, lib, config, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      ZSH_TMUX_AUTOSTART=true
      ZSH_TMUX_FIXTERM=false
      ZSH_TMUX_CONFIG=$HOME/.config/tmux/tmux.conf


      # Define an init function and append to zvm_after_init_commands
      function my_init() {
        # This is copied from the fzf program zsh integration, but we want to make sure we do it here...
        if [[ $options[zle] = on ]]; then
          source <(${lib.getExe config.programs.fzf.package} --zsh)
        fi
      }
      zvm_after_init_commands+=(my_init)
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

{ ... }:
{
  programs = {
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        format = ''
          [----$time----](bold green)
          [|](bold green) $hostname$localip$shlvl$singularity$kubernetes$directory$vcsh$fossil_branch$fossil_metrics$git_branch$git_commit$git_state$git_metrics$git_status$hg_branch$pijul_channel$docker_context$package$c$cmake$cobol$daml$dart$deno$dotnet$elixir$elm$erlang$fennel$gleam$golang$guix_shell$haskell$haxe$helm$java$julia$kotlin$gradle$lua$nim$nodejs$ocaml$opa$perl$php$pulumi$purescript$python$quarto$raku$rlang$red$ruby$rust$scala$solidity$swift$terraform$typst$vlang$vagrant$zig$buf$nix_shell$conda$meson$spack$memory_usage$aws$gcloud$openstack$azure$nats$direnv$env_var$mise$crystal$custom$sudo$cmd_duration$jobs$battery$status$os$container$netns$shell
          [--](bold green)$character'';

        character = {
          success_symbol = "[->](bold green) ";
          error_symbol = "[->](bold red) ";
          vimcmd_symbol = "[!>](bold green) ";
          vimcmd_replace_one_symbol = "[!>](bold purple) ";
          vimcmd_replace_symbol = "[!>](bold purple) ";
          vimcmd_visual_symbol = "[!>](bold purple) ";
        };

        time = {
          disabled = false;
          format = " [$time]($style) ";
        };
      };
    };
  };
}

{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pi-coding-agent;
  settingsPath = "${cfg.configDir}/settings.json";
  settingsFile = (pkgs.formats.json { }).generate "pi-coding-agent-settings.json" cfg.settings;
in
{
  programs.pi-coding-agent = {
    enable = true;
    package = pkgs.pi;
    settings = {
      enableInstallTelemetry = false;
      # `pi install`/`pi update` shell out to npm; this avoids needing node on PATH.
      npmCommand = [ "nix" "shell" "nixpkgs#nodejs" "--command" "npm" ];
      # Share skills with Claude Code.
      skills = [ "~/.claude/skills" ];
    };
  };

  # pi rewrites settings.json itself (`pi install`, /model, changelog version), so rather than the
  # module's read-only store symlink, merge the declared settings into a writable copy on each switch.
  # Declared keys win; keys pi added itself are kept.
  home.file.${settingsPath}.enable = false;
  home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings=${lib.escapeShellArg settingsPath}
    run mkdir -p "$(dirname "$settings")"
    if [[ -L $settings ]]; then run rm "$settings"; fi
    merged=$(mktemp)
    ${lib.getExe pkgs.jq} -s '.[0] * .[1]' \
      <(cat "$settings" 2>/dev/null || echo '{}') ${settingsFile} >"$merged"
    run mv "$merged" "$settings"
    run chmod 644 "$settings"
  '';
}

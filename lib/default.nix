{ inputs, localOverlays, stateVersion }:
let lib = inputs.nixpkgs.lib; in rec {
  libx = lib // {
    mkTieredEnableOption = parent: desc: (lib.mkEnableOption desc) // {
      apply = x: parent.enable && x;
    };

    mkSecret = name: { ... }@args: ({
      file = "${inputs.self}/secrets/${name}.age";
    } // args);
  };

  mkHost =
    { hostname
    , configname ? hostname
    , system ? "x86_64-linux"
    }: {
      "${hostname}" = lib.nixosSystem {
        inherit system;

        specialArgs = { inherit hostname configname inputs stateVersion libx; };

        modules = [
          inputs.agenix.nixosModules.default
          ({ ... }: {
            nixpkgs.overlays = [
              localOverlays.default
              inputs.agenix.overlays.default
            ];
          })
          ../host
        ];
      };
    };

  mkHosts = hosts: lib.mergeAttrsList (map mkHost hosts);


  # The whole home config, minus `username`/`stateVersion` (passed via extraSpecialArgs).
  # Exported as homeModules.default so other flakes can layer machine-specific modules on top.
  homeModule = {
    imports = [
      inputs.catppuccin.homeModules.catppuccin
      ../home
    ];
    nixpkgs.overlays = [
      localOverlays.default
      inputs.agenix.overlays.default
      # Built against pi's own pinned nixpkgs, not ours.
      (final: _: { pi = inputs.pi.packages.${final.stdenv.hostPlatform.system}.default; })
    ];
  };

  mkHostHome = { username, host }: {
    "${username}@${host.config.networking.hostName}" = inputs.home-manager.lib.homeManagerConfiguration {
      inherit (host) pkgs;
      extraSpecialArgs = {
        inherit username inputs stateVersion;
      };

      modules = [ homeModule ];
    };
  };


  mkHome = { username, hosts }: lib.mergeAttrsList (map (host: mkHostHome { inherit username host; }) hosts);

  mkHomes = homes: lib.mergeAttrsList (map mkHome homes);
}

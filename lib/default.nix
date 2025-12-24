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
          inputs.harmonia.nixosModules.harmonia
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


  mkHostHome = { username, host }: {
    "${username}@${host.config.networking.hostName}" = inputs.home-manager.lib.homeManagerConfiguration {
      inherit (host) pkgs;
      extraSpecialArgs = {
        inherit username inputs stateVersion;
      };

      modules = [
        inputs.catppuccin.homeModules.catppuccin
        ({ ... }: {
          nixpkgs.overlays = [
            localOverlays.default
            inputs.agenix.overlays.default
          ];
        })
        ../home
      ];
    };
  };


  mkHome = { username, hosts }: lib.mergeAttrsList (map (host: mkHostHome { inherit username host; }) hosts);

  mkHomes = homes: lib.mergeAttrsList (map mkHome homes);
}

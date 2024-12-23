{ inputs, outputs, stateVersion }:
let lib = inputs.nixpkgs.lib; in rec {
  mkHost =
    { hostname
    , system ? "x86_64-linux"
    }: {
      "${hostname}" = lib.nixosSystem {
        inherit system;

        specialArgs = { inherit hostname inputs outputs stateVersion; };

        modules = [
          inputs.agenix.nixosModules.default
          ../host
        ];
      };
    };

  mkHosts = hosts: lib.mergeAttrsList (map mkHost hosts);


  mkHostHome = { username, hostname }:
    let host = outputs.nixosConfigurations.${hostname}; in {
      "${username}@${host.config.networking.hostName}" = inputs.home-manager.lib.homeManagerConfiguration {
        inherit (host) pkgs;
        extraSpecialArgs = {
          inherit username inputs outputs stateVersion;
        };

        modules = [
          inputs.catppuccin.homeManagerModules.catppuccin
          ../home
        ];
      };
    };


  mkHome = { username, hosts }: lib.mergeAttrsList (map (hostname: mkHostHome { inherit username hostname; }) hosts);

  mkHomes = homes: lib.mergeAttrsList (map mkHome homes);
}

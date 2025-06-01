{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt.url = "github:numtide/treefmt-nix";

    git-hooks.url = "github:cachix/git-hooks.nix";

    mkdocs-flake.url = "github:applicative-systems/mkdocs-flake";
  };

  outputs = inputs:
    let localOverlays = import ./overlays; in inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      # (2) import mkdocs-flake module
      imports = [
        inputs.home-manager.flakeModules.home-manager
        inputs.git-hooks.flakeModule
        inputs.treefmt.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      flake =
        let
          libx = import ./lib {
            inherit inputs localOverlays;
            stateVersion = "25.05";
          };
        in
        rec {
          nixosConfigurations = libx.mkHosts [
            {
              hostname = "generic";
              system = "x86_64-linux";
            }
            {
              hostname = "rabin";
              system = "x86_64-linux";
            }
          ];
          homeConfigurations = libx.mkHomes [
            {
              username = "admin";
              hosts = [ nixosConfigurations.rabin ];
            }
            {
              username = "bcape";
              hosts = [ nixosConfigurations.generic nixosConfigurations.rabin ];
            }
          ];
          overlays = localOverlays;
        };
      perSystem = { pkgs, system, config, ... }: {

        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            localOverlays.default
          ];
        };

        treefmt = {

          # Used to find the project root
          projectRootFile = "flake.nix";

          settings = {
            global = {
              excludes = [ "*.age" "*.cfg" "*.conf" ];
            };
          };

          programs = {
            jsonfmt.enable = true;
            nixpkgs-fmt.enable = true;
            shellcheck.enable = true;
            ruff.enable = true;
            deadnix.enable = true;
          };

        };

        pre-commit.settings.hooks.treefmt.enable = true;

        devShells.default = pkgs.mkShell {
          shellHook = ''
            ${config.pre-commit.installationScript}
            echo 1>&2 "Welcome to the development shell!"
          '';
        };
      };
    };
}

{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-24.11";
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

    utils.url = "github:numtide/flake-utils";

    catppuccin.url = "github:catppuccin/nix";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , fenix
    , utils
    , treefmt-nix
    , agenix
    , ...
    }@inputs:
    let

      libx = import ./lib {
        inherit inputs;
        inherit (self) outputs;
        stateVersion = "24.11";
      };

      systemSpecific = utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          # Eval the treefmt modules from ./treefmt.nix
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        in
        {
          packages = { inherit pkgs; };
          formatter = treefmtEval.config.build.wrapper;
        }
      );
    in
    systemSpecific
    // {
      nixosConfigurations = libx.mkHosts [
        {
          hostname = "rabin";
          system = "aarch64-linux";
        }
      ];
      homeConfigurations = libx.mkHomes [
        {
          username = "bcape";
          hosts = [ "rabin" ];
        }
      ];
      overlays = import ./overlays;
    };
}

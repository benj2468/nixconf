{ pkgs, inputs, hostname, config, lib, ... }:
{
  imports = [
    ./configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    vscode
  ];
}

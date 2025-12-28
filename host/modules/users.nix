{ pkgs, libx, config, ... }:
let
  admin-keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIpz1QY/LidJUEHlU0exA55GnjFhxRgLFHHxkXhJ4NDjyHg/1u5E3+rr/dm/tpzObMDl7mlKotQCkXPW9vBpBPTPycRdshKuZQ4gzuLBWIGrVGNaZ+stdRehUb3wsJq1rbzG63rL3/GWBrtyVN39K157QAmwz66//RHqzE8DNbGrpUxX8LknMSbU/SAP4TvipzHoEHCl12qXRp4U5R/nLBPDNAgcLqYuB7zcbQt00LG3sKX8PCyV8UqKL+kPmVqlQJ4wjbf017Ua8aJYE4yfenjA/YpeCCLkRt0vmlHgMc/kojiIIqC0rYWvUcDlGCdWPMEXhU72vDHkNVWo5fzqEeWLvhiZGNeqZYepUBnPBlFas2GKUE7WSZ39jXZLSWsCg6qFMAWtqusa5TlRPk1dQcY4H8ALUJMPoK+36f16IRdqwpM2rKzZp5FaUkim+nzcpYu3wBLgi4kQr4Nz7PFIUglhdWD0kjFqjJCoon2bdqgCSBGqLZHWbaJ5zkZEeEk6k="
  ];

  ci-keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXh0o4uVA8vU3fXq9MAJVzg7Q+y+SMF7N4xgtM78Yt4"
  ];

  optionalLibVirt = libx.optionals config.virtualisation.libvirtd.enable [ "libvirtd" ];
in
{

  options.haganah.users = {
    enable = libx.mkTieredEnableOption config.haganah "Enable the Haganah Graphical Configurations" // {
      default = true;
    };
  };

  config = libx.mkIf config.haganah.users.enable {

    nix.settings.trusted-users = [ "bcape" "admin" "ci" ];

    users.users.bcape = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "docker" "users" ] ++ optionalLibVirt;
      description = "Benjamin Cape";
      shell = pkgs.zsh;

      openssh.authorizedKeys.keys = admin-keys;
    };

    users.users.admin = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" "docker" ] ++ optionalLibVirt;
      description = "System Administrator";
      shell = pkgs.zsh;

      openssh.authorizedKeys.keys = admin-keys;
    };

    users.users.ci = {
      isSystemUser = true;
      group = "ci";
      description = "CI User";
      shell = pkgs.zsh;

      openssh.authorizedKeys.keys = ci-keys;
    };

    users.groups.ci = { };
  };
}

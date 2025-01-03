{ pkgs, lib, config, ... }:
{
  programs.zsh.enable = true;

  users.users.gitlab = {
    openssh.authorizedKeys.keys = config.users.users.bcape.openssh.authorizedKeys.keys;
    home = lib.mkForce "/home/gitlab";
    extraGroups = [ "wheel" ];
    shell = lib.mkForce pkgs.zsh;
  };

  users.users.bcape = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "users" ];
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIpz1QY/LidJUEHlU0exA55GnjFhxRgLFHHxkXhJ4NDjyHg/1u5E3+rr/dm/tpzObMDl7mlKotQCkXPW9vBpBPTPycRdshKuZQ4gzuLBWIGrVGNaZ+stdRehUb3wsJq1rbzG63rL3/GWBrtyVN39K157QAmwz66//RHqzE8DNbGrpUxX8LknMSbU/SAP4TvipzHoEHCl12qXRp4U5R/nLBPDNAgcLqYuB7zcbQt00LG3sKX8PCyV8UqKL+kPmVqlQJ4wjbf017Ua8aJYE4yfenjA/YpeCCLkRt0vmlHgMc/kojiIIqC0rYWvUcDlGCdWPMEXhU72vDHkNVWo5fzqEeWLvhiZGNeqZYepUBnPBlFas2GKUE7WSZ39jXZLSWsCg6qFMAWtqusa5TlRPk1dQcY4H8ALUJMPoK+36f16IRdqwpM2rKzZp5FaUkim+nzcpYu3wBLgi4kQr4Nz7PFIUglhdWD0kjFqjJCoon2bdqgCSBGqLZHWbaJ5zkZEeEk6k="
    ];
  };
}

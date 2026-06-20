{ ... }:
{
  systemd.tmpfiles.rules = [
    "d /sccache 0755 root root -"
  ];
}

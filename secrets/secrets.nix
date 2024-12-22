let
  bcape = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5c/hYJj1isWsH5H3hYuMjS0+SGNngdPnx2B6V33elV";
  rabin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMaK9wlLa5VuXWkQ+cn71VGtjCZbhBHYADIuTDPiE2Qr";

  users = [ bcape ];
in
{
  "rabin-dashboard.age".publicKeys = users ++ [ rabin ];
}

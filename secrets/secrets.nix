let
  bcape = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5c/hYJj1isWsH5H3hYuMjS0+SGNngdPnx2B6V33elV";
  gitlab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICm2Quqogy7P01db3HV3hNfYJp5WA0FLF9rrLdV4zc1P";

  rabin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMaK9wlLa5VuXWkQ+cn71VGtjCZbhBHYADIuTDPiE2Qr";

  users = [ bcape ];
in
{
  "rabin-dashboard.age".publicKeys = users ++ [ rabin ];

  "rabin-gitlab-db.age".publicKeys = [ bcape gitlab rabin ];
  "rabin-gitlab-runner-1-tokens.age".publicKeys = [ bcape gitlab rabin ];
}

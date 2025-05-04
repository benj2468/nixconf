let
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIuNWcOuPAj6eArZ2t513v7FoTRJq9gOvYKRwzXuzRsp";
  rabin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINYMenqlLPuRmlCEwRPNlFq74ME7oPi6imEBvi5Gc6d3";

  users = [ admin ];
in
{
  "rabin-dashboard.age".publicKeys = users ++ [ rabin ];
}

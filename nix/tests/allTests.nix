{ nixosTest }:
rec {
  loghost = nixosTest (import ./loghost.nix);
}

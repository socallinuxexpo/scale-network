{ nixosTest }:
rec {
  loghost = nixosTest (import ./loghost.nix);
  core = nixosTest (import ./core.nix);
}

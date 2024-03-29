{
  nixConfig.bash-prompt = "\\[\\033[01;32m\\][nix-flakes \\W] \$\\[\\033[00m\\] ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs-lib.follows = "nixpkgs"; };
    microvm = { url = "github:sarcasticadmin/microvm.nix/rh/1707108673virtio"; inputs.nixpkgs.follows = "nixpkgs"; inputs.spectrum.follows = ""; }; # Currently using this fork since the upstream seems to be causing an issue
  };


  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      imports = [
        ./nix/flake-module.nix
      ];
    };
}

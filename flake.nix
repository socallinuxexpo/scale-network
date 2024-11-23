{
  nixConfig.bash-prompt = "\\[\\033[01;32m\\][nix-flakes \\W] \$\\[\\033[00m\\] ";

  inputs = {
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    microvm = {
      url = "github:sarcasticadmin/microvm.nix/rh/1707108673virtio";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.spectrum.follows = "";
    }; # Currently using this fork since the upstream seems to be causing an issue
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    disko = {
      url = "github:nix-community/disko/e55f9a8678adc02024a4877c2a403e3f6daf24fe";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    inputs:
    (inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [ ./nix/flake-module.nix ];
    })
    // {
      formatter = import ./nix/formatter inputs;
      formatterModule = import ./nix/formatterModule inputs;
      nixosModules = import ./nix/nixos-modules inputs;
    };
}

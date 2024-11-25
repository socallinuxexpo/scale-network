{
  nixConfig.bash-prompt = "\\[\\033[01;32m\\][nix-flakes \\W] \$\\[\\033[00m\\] ";

  inputs = {
    disko.inputs.nixpkgs.follows = "nixpkgs-unstable";
    disko.url = "github:nix-community/disko/e55f9a8678adc02024a4877c2a403e3f6daf24fe";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-2405";
    flake-parts.url = "github:hercules-ci/flake-parts";
    microvm.inputs.nixpkgs.follows = "nixpkgs-2405";
    microvm.inputs.spectrum.follows = "";
    # Currently using this fork since the upstream seems to be causing an issue
    microvm.url = "github:sarcasticadmin/microvm.nix/rh/1707108673virtio";
    nixpkgs-2405.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-2405";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs: {
    checks = import ./nix/checks inputs;
    devShells = import ./nix/dev-shells inputs;
    formatter = import ./nix/formatter inputs;
    formatterModule = import ./nix/formatterModule inputs;
    legacyPackages = import ./nix/legacy-packages inputs;
    library = import ./nix/library inputs;
    nixosModules = import ./nix/nixos-modules inputs;
    nixosConfigurations = import ./nix/nixos-configurations inputs;
    overlays = import ./nix/overlays inputs;
  };
}

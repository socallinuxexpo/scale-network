{
  nixConfig.bash-prompt = "\\[\\033[01;32m\\][nix-flakes \\W] \$\\[\\033[00m\\] ";

  inputs = {
    disko.inputs.nixpkgs.follows = "nixpkgs-unstable";
    disko.url = "github:nix-community/disko/e55f9a8678adc02024a4877c2a403e3f6daf24fe";
    microvm.inputs.nixpkgs.follows = "nixpkgs-2405";
    microvm.inputs.spectrum.follows = "";
    # Currently using this fork since the upstream seems to be causing an issue
    microvm.url = "github:sarcasticadmin/microvm.nix/rh/1707108673virtio";
    # nixpkgs-2405 has been pinned to this rev to maintain parity from before flake-parts was removed
    # If you want to bump this input, change it back to `github:NixOS/nixpkgs/nixos-24.05` and lock the flake again
    nixpkgs-2405.url = "github:NixOS/nixpkgs?rev=d51c28603def282a24fa034bcb007e2bcb5b5dd0";
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
    nixosConfigurations = import ./nix/nixos-configurations inputs;
    nixosModules = import ./nix/nixos-modules inputs;
    overlays = import ./nix/overlays inputs;
    packages = import ./nix/packages inputs;
  };
}

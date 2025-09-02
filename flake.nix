{
  nixConfig.bash-prompt = "\\[\\033[01;32m\\][nix-flakes \\W] \$\\[\\033[00m\\] ";

  inputs = {
    disko.inputs.nixpkgs.follows = "nixpkgs-unstable";
    disko.url = "github:nix-community/disko";
    nixpkgs-2505.url = "github:NixOS/nixpkgs";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-unstable";
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

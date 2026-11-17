{
  nixConfig.bash-prompt = "\\[\\033[01;32m\\][nix-flakes \\W] \$\\[\\033[00m\\] ";

  inputs = {
    disko.inputs.nixpkgs.follows = "nixpkgs-unstable";
    disko.url = "github:nix-community/disko";
    mixos.follows = "openwrt-one-nix/mixos";
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-unstable";
    openwrt-one-nix.inputs.nixpkgs.follows = "nixpkgs";
    openwrt-one-nix.url = "git+https://codeberg.org/jmbaur/openwrt-one.nix";
    openwrt-one-nix.inputs.mixos.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs: {
    checks = import ./nix/checks inputs;
    devShells = import ./nix/dev-shells inputs;
    formatter = import ./nix/formatter inputs;
    formatterModule = import ./nix/formatterModule inputs;
    hydraJobs = import ./nix/hydra-jobs inputs;
    legacyPackages = import ./nix/legacy-packages inputs;
    legacyPackagesTests = import ./nix/legacy-packages/tests.nix inputs;
    library = import ./nix/library inputs;
    mixosConfigurations = import ./nix/mixos-configurations inputs;
    nixosConfigurations = import ./nix/nixos-configurations inputs;
    nixosModules = import ./nix/nixos-modules inputs;
    overlays = import ./nix/overlays inputs;
    packages = import ./nix/packages inputs;
  };
}

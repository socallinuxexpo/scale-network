{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs, ... }:
    let
      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlays.default ]; });
    in
    {
      overlays.default = (final: prev:
        with final.pkgs;
        rec {
          scaleTests = callPackage ./nix/tests/allTests.nix { };
          massflash = callPackage ./nix/pkgs/massflash.nix { };
          scaleInventory = callPackage ./nix/pkgs/scaleInventory.nix { };
        });

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) scaleTests scaleInventory;
      });

      nixosConfigurations =
        let
          # All scale common modules
          system = "x86_64-linux";
          common =
            ({ modulesPath, ... }: {
              imports = [
                ./nix/modules/bhyve-image.nix
                ./nix/machines/_common/users.nix
              ];
            });
          pkgs = nixpkgsFor.${system};
        in
        {
          loghost = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              common
              ./nix/machines/loghost.nix
            ];
          };
          massflash = nixpkgs.lib.nixosSystem {
            inherit system pkgs;
            modules = [
              ({ modulesPath, ... }: {
                imports = [
                  "${toString modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
                ];
              })
              ./nix/machines/massflash.nix
            ];
          };
          coreMaster = nixpkgs.lib.nixosSystem {
            inherit system pkgs;
            modules = [
              common
              ./nix/machines/core/master.nix
            ];
            specialArgs = { inherit self; };
          };
          coreSlave = nixpkgs.lib.nixosSystem {
            inherit system pkgs;
            modules = [
              common
              ./nix/machines/core/slave.nix
            ];
          };
          signs = nixpkgs.lib.nixosSystem {
            inherit system pkgs;
            modules = [
              common
              ./nix/machines/signs.nix
            ];
          };
        };

      # Like nix-shell
      # Good example: https://github.com/tcdi/pgx/blob/master/flake.nix
      devShells = forAllSystems
        (system:
          let
            pkgs = nixpkgsFor.${system};
          in
          {
            default = import ./shell.nix { inherit pkgs; };
          });

      checks =
        let
          pkgs = nixpkgsFor.x86_64-linux;
        in
        {
          # python tests for the data found in facts
          # disabling persistence and cache for py utils to avoid warnings
          # since caching is taken care of by nix
          pytest-facts = pkgs.runCommand "pytest-facts" { } ''
            cp -r ${pkgs.lib.cleanSource self}/* .
            cd facts
            ${pkgs.python3Packages.pylint}/bin/pylint --persistent n *.py
            ${pkgs.python3Packages.pytest}/bin/pytest -vv -p no:cacheprovider
            touch $out
          '';
          perl-switches = pkgs.runCommand "perl-switches"
            {
              buildInputs = [ pkgs.gnumake pkgs.perl ];
            } ''
            cp -r ${pkgs.lib.cleanSource self}/* .
            cd switch-configuration
            make .lint
            make .build-switch-configs 
            touch $out
          '';

        };
    };

  # Bold green prompt for `nix develop`
  # Had to add extra escape chars to each special char
  nixConfig.bash-prompt = "\\[\\033[01;32m\\][nix-flakes \\W] \$\\[\\033[00m\\] ";
}

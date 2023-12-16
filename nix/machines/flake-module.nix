{ lib, inputs, ... }:

let
  # All scale common modules
  system = "x86_64-linux";
  common = {
    imports = [
      inputs.self.nixosModules.bhyve-image
      ./_common/users.nix
    ];
  };
in
{
  flake.nixosConfigurations =
    {
      bootstrapImage = lib.nixosSystem {
        inherit system;
        modules = [
          ({ modulesPath, ... }: {
            imports = [
              "${ toString modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
            ];
          })
          ./_common/users.nix
          ./bootstrap.nix
        ];
        specialArgs = { inherit inputs; };
      };
      loghost = lib.nixosSystem {
        inherit system;
        modules = [
          common
          ./loghost.nix
        ];
        specialArgs = { inherit inputs; };
      };
      massflash = lib.nixosSystem {
        inherit system;
        modules = [
          ({ modulesPath, ... }: {
            imports = [
              "${ toString modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
            ];
          })
          ./massflash.nix
        ];
        specialArgs = { inherit inputs; };
      };
      coreMaster = lib.nixosSystem {
        inherit system;
        modules = [
          common
          ./core/master.nix
        ];
        specialArgs = { inherit inputs; };
      };
      coreSlave = lib.nixosSystem {
        inherit system;
        modules = [
          common
          ./core/slave.nix
        ];
        specialArgs = { inherit inputs; };
      };
      signs = lib.nixosSystem {
        inherit system;
        modules = [
          common
          ./signs.nix
        ];
        specialArgs = { inherit inputs; };
      };
    };


}

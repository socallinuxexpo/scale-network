inputs:

let
  inherit (builtins) mapAttrs;
  inherit (inputs.nixpkgs.lib) filterAttrs const;
in

mapAttrs (
  directory: _:
  inputs.mixos.lib.mixosSystem {
    modules = [
      ./${directory}
      inputs.openwrt-one-nix.mixosModules.default
      {
        nixpkgs.pkgs = import inputs.nixpkgs {
          localSystem = "x86_64-linux";
          crossSystem = "aarch64-linux";
          overlays = [ inputs.self.overlays.default ];
        };
      }
    ];
  }
) (filterAttrs (const (entryType: entryType == "directory")) (builtins.readDir ./.))

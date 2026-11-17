inputs:

let
  inherit (builtins) mapAttrs;
  inherit (inputs.nixpkgs.lib) filterAttrs const;
in

mapAttrs (
  directory:
  const (
    inputs.mixos.lib.mixosSystem {
      modules = [
        ./${directory}
        inputs.openwrt-one-nix.mixosModules.default
        {
          nixpkgs.pkgs = import inputs.nixpkgs {
            localSystem = "x86_64-linux";
            crossSystem.config = "aarch64-unknown-linux-musl";
            overlays = [
              inputs.self.overlays.default
              inputs.openwrt-one-nix.overlays.default
            ];
          };
        }
      ];
    }
  )
) (filterAttrs (const (entryType: entryType == "directory")) (builtins.readDir ./.))

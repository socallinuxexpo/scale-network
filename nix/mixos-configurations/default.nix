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
        nixpkgs = {
          nixpkgs = inputs.nixpkgs-2511;
          overlays = [ inputs.self.overlays.default ];
        };
      }
    ];
  }
) (filterAttrs (const (entryType: entryType == "directory")) (builtins.readDir ./.))

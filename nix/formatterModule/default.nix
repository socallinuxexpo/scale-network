inputs:
let

  inherit (inputs.nixpkgs)
    lib
    ;

  inherit (lib.attrsets)
    mapAttrs
    ;

  inherit (lib.trivial)
    const
    ;

in
mapAttrs (const (
  pkgs:
  (inputs.treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
    programs.ruff-format.enable = true;
    programs.ruff-check.enable = true;
    programs.mdformat.enable = true;
    programs.yamlfmt.enable = true;
  })
)) inputs.self.legacyPackages

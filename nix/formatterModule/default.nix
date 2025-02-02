inputs:
inputs.self.library.defaultSystems (
  system:
  let
    pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
  in
  (inputs.treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
    programs.ruff-format.enable = true;
    programs.ruff-check.enable = true;
    programs.mdformat.enable = true;
    programs.yamlfmt.enable = true;
  })
)

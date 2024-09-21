inputs:
inputs.nixpkgs-unstable.lib.genAttrs
  [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ]
  (
    system:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
    (inputs.treefmt-nix.lib.evalModule pkgs {
      projectRootFile = "flake.nix";
      programs.nixfmt.enable = true;
    }).config.build.wrapper
  )

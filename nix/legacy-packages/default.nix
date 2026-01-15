inputs:
inputs.nixpkgs-lib.lib.genAttrs
  [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ]
  (
    system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [ inputs.self.overlays.default ];
    }
  )

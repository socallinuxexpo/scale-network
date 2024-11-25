inputs:
inputs.nixpkgs-unstable.lib.genAttrs
  [
    "x86_64-linux"
    "aarch64-linux"
  ]
  (
    system:
    import inputs.nixpkgs-unstable {
      inherit system;
      overlays = [ inputs.self.overlays.default ];
    }
  )

inputs:
inputs.nixpkgs.lib.genAttrs
  [
    "x86_64-linux"
    "aarch64-linux"
  ]
  (
    system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [ inputs.self.overlays.default ];
    }
  )

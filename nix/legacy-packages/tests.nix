inputs:
inputs.self.library.systems.defaultSystems (
  system:
  import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.self.overlays.default
      inputs.self.overlays.scale-tests
    ];
  }
)

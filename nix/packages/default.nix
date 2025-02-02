inputs:
inputs.self.library.defaultSystems (system: {
  inherit (inputs.self.legacyPackages.${system}.scale-network)
    massflash
    scaleInventory
    serverspec
    ;
})

{
  perSystem = { pkgs, ... }: {
    packages = {
      massflash = pkgs.callPackage ./massflash.nix { };
      scaleInventory = pkgs.callPackage ./scaleInventory.nix { };
    };
  };
}

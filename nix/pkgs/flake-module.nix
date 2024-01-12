{
  perSystem = { pkgs, ... }: {
    packages = {
      serverspec = pkgs.callPackage ./serverspec {};
      massflash = pkgs.callPackage ./massflash.nix { };
      scaleInventory = pkgs.callPackage ./scaleInventory.nix { };
    };
  };
}

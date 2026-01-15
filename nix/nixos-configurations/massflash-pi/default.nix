{
  release = "unstable";

  modules =
    {
      modulesPath,
      ...
    }:
    {
      imports = [
        "${modulesPath}/installer/sd-card/sd-image-aarch64-installer.nix"
      ];

      config = {
        nixpkgs.hostPlatform = "aarch64-linux";
        scale-network.massflash.enable = true;

        scale-network = {
          base.enable = true;

          users.berkhan.enable = true;
          users.dlang.enable = true;
          users.jsh.enable = true;
          users.kylerisse.enable = true;
          users.owen.enable = true;
          users.rhamel.enable = true;
          users.rob.enable = true;
          users.root.enable = true;
          users.ruebenramirez.enable = true;
        };
      };
    };
}

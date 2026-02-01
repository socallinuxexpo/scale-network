{
  release = "unstable";

  modules =
    {
      modulesPath,
      ...
    }:
    {
      imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
      ];

      config = {
        nixpkgs.hostPlatform = "x86_64-linux";
        scale-network.massflash.enable = true;

        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
          autoResize = true;
        };
        boot.growPartition = true;
        # Todo: figure out console+monitor output
        #boot.kernelParams = [ "console=ttyS0" ];
        boot.loader.grub.device = "/dev/vda";

        scale-network = {
          base.enable = true;

          users.berkhan.enable = true;
          users.djacu.enable = true;
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

{
  release = "2405";

  modules =
    {
      inputs,
      ...
    }:
    {
      imports = [
        inputs.microvm.nixosModules.host
        ./configuration.nix
        ./hardware-configuration.nix
      ];

      config = {
        nixpkgs.hostPlatform = "x86_64-linux";

        scale-network = {
          base.enable = true;
          services.prometheus.enable = true;
          libvirt.enable = true;

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

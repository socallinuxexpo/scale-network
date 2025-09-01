{
  release = "unstable";

  modules =
    {
      modulesPath,
      pkgs,
      ...
    }:
    let
      mybootstrap = pkgs.writeShellScriptBin "mybootstrap" (builtins.readFile ./bootstrap.sh);
    in
    {
      imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
      ];

      config = {
        nixpkgs.hostPlatform = "x86_64-linux";

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

        nix.extraOptions = ''
          experimental-features = nix-command flakes
        '';

        networking = {
          useNetworkd = true;
          useDHCP = false;
          firewall.enable = true;
        };

        systemd.network = {
          enable = true;
          networks = {
            "10-lan" = {
              matchConfig.Name = "eno1";
              enable = true;
              networkConfig.DHCP = "yes";
            };
          };
        };

        environment.systemPackages = with pkgs; [
          wget
          git
          vim
          efibootmgr
          gptfdisk
          screen
          mybootstrap
        ];

        services.openssh = {
          enable = true;
          openFirewall = true;
        };

      };
    };
}

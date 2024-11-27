{
  release = "2405";

  modules =
    {
      pkgs,
      ...
    }:
    {
      imports = [
        ./disko.nix
        ./hardware-configuration.nix
      ];

      config = {
        nixpkgs.hostPlatform = "x86_64-linux";

        scale-network = {
          base.enable = true;
          libvirt.enable = true;
          services.gitlab.enable = true;
          services.prometheus.enable = false;
          services.ssh4vms.enable = false;
          timeServers.enable = false;

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
        ];

        services.openssh = {
          enable = true;
          openFirewall = true;
        };

      };
    };
}

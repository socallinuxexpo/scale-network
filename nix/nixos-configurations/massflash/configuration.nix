{
  lib,
  pkgs,
  ...
}:
let
  addtobr = pkgs.writeShellScriptBin "addtobr" ''
    [ -z "$1" ] && echo "Please pass in network device" && exit 1
    ip link set $1 master br0
    bridge vlan add dev $1 vid 503
    ip link set $1 up
  '';
in
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };
  boot.growPartition = true;
  # Todo: figure out console+monitor output
  #boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.grub.device = "/dev/vda";

  systemd.network = {
    enable = true;
    netdevs = {
      br0 = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
        };
        bridgeConfig.VLANFiltering = true;
      };

      flash = {
        netdevConfig = {
          Kind = "veth";
          Name = "flash0";
        };
        peerConfig = {
          Name = "flash1";
        };
      };
      flash503 = {
        vlanConfig = {
          Id = 503;
        };
        netdevConfig = {
          Kind = "vlan";
          Name = "flash0.503";
        };
      };
    };
    # Nice example: https://github.com/NixOS/nixpkgs/issues/16230#issuecomment-272331072
    networks = {
      br0 = {
        matchConfig.Name = "br0";
      };

      flash0 = {
        matchConfig.Name = "flash0";
        networkConfig.VLAN = "flash0.503";
      };

      flash503 = {
        matchConfig.Name = "flash0.503";
        networkConfig.Address = "192.168.252.1/22";
      };

      flash1 = {
        matchConfig.Name = "flash1";
        networkConfig.Bridge = "br0";
        bridgeVLANs = [ { VLAN = 503; } ];
      };
    };
  };
  networking = {
    networkmanager.enable = lib.mkForce false;
    useDHCP = false;
    # Make sure that dhcpcd doesnt timeout when interfaces are down
    # ref: https://nixos.org/manual/nixos/stable/options.html#opt-networking.dhcpcd.wait
    dhcpcd.wait = "background";
    hostName = "massflash";

    # Assuming wifi device name
    # TODO: fix to make agnositic like flash0
    wireless = {
      enable = true;
      userControlled.enable = true;
    };

    interfaces.wlp3s0.useDHCP = true;
  };

  # root user doesnt need credentials for massflash liveCD
  users.extraUsers.root.password = lib.mkForce "";

  # we set the hashedPassword in _common so just ensure that this is actually null
  users.extraUsers.root.hashedPassword = lib.mkForce null;

  security.sudo.wheelNeedsPassword = false;

  environment = {
    systemPackages =
      with pkgs;
      [
        expect
        git
        kea
        scale-network.massflash
        unixtools.ping
        tmux
        vim
      ]
      ++ [ addtobr ];

    etc."massflash.conf" = {
      text = ''
        state_dir="/persist/massflash"
      '';
    };
  };

  services = {
    openssh = {
      enable = true;
    };
    kea = {
      dhcp4 = {
        extraArgs = [
          # Disable Kea's "security checks". Without this, Kea refuses to run
          # the script we've configured to run via libdhcp_run_script.so
          # because it's not in the "supported path".
          "-X"
        ];
        enable = true;
        configFile =
          pkgs.writeText "keaconfig" # json
            ''
              {
                "Dhcp4": {
                  "interfaces-config": {
                    "interfaces": [
                      "flash0.503"
                    ],
                    "dhcp-socket-type": "raw"
                  },
                  "valid-lifetime": 600,
                  "renew-timer": 300,
                  "rebind-timer": 400,
                  "subnet4": [
                    {
                      "id": 1921682520,
                      "subnet": "192.168.252.0/22",
                      "pools": [
                        {
                          "pool": "192.168.252.50-192.168.254.254"
                        }
                      ]
                    }
                  ],
                  "loggers": [
                    {
                      "name": "*",
                      "severity": "DEBUG"
                    }
                  ],
                  "hooks-libraries": [
                    {
                      "library": "${pkgs.kea}/lib/kea/hooks/libdhcp_run_script.so",
                      "parameters": {
                        "name": "${pkgs.scale-network.massflash}/bin/massflash",
                        "sync": false
                      }
                    }
                  ]
                }
              }
            '';
      };
    };
  };

}

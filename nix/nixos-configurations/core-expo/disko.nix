{
  disko.devices = {
    disk = {
      one = {
        type = "disk";
        device = "/dev/disk/by-path/pci-0000:10:00.0-scsi-0:0:10:0";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank0";
              };
            };
          };
        };
      };
      two = {
        type = "disk";
        device = "/dev/disk/by-path/pci-0000:10:00.0-scsi-0:0:9:0";
        content = {
          type = "gpt";
          partitions = {
            # Support multiple disks to boot from
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot2";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank0";
              };
            };
          };
        };
      };
    };
    zpool = {
      tank0 = {
        type = "zpool";
        mode = "mirror";
        # Workaround: cannot import 'tank0': I/O error in disko tests
        options.cachefile = "none";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "true";
          acltype = "posixacl";
          xattr = "sa";
          canmount = "off";
          mountpoint = "none";
        };
        options = {
          ashift = "12";
          autotrim = "on";
        };

        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          "home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };
          "persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}

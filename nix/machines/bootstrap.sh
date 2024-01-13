blkdiscard -f /dev/sda
blkdiscard -f /dev/sdc

sgdisk -Z /dev/sda
sgdisk -Z /dev/sdc

sgdisk -g -n1:1M:+512M -t1:EF00 /dev/sda

sgdisk -g -n2:0:0 -t2:BF01 /dev/sda # rest of drive

# alternative to #sfdisk --dump /dev/sda | sfdisk /dev/sdc
sgdisk /dev/sda -R /dev/sdc
sgdisk -G /dev/sdc # Confirm with blkid

zpool create -f -O mountpoint=none -O atime=off -o ashift=12 -O acltype=posixacl -O xattr=sa -O compression=lz4 zroot mirror /dev/sda2 /dev/sdc2

# Create ZFS datasets
zfs create -p -o mountpoint=legacy zroot/root      # For /
zfs snapshot zroot/root@blank
zfs create -o mountpoint=legacy zroot/home # For /home
zfs create -o mountpoint=legacy zroot/nix  # For /nix
zfs create -o mountpoint=legacy zroot/persist  # For /persist

# Create ESP partiions
mkfs.vfat /dev/sda1
mkfs.vfat /dev/sdc1

# Mount new ZFS pool
mount -t zfs zroot/root /mnt

# Create directories to mount file systems on
mkdir /mnt/{nix,home,boot,boot2}

# Mount the rest of the ZFS file systems
mount -t zfs zroot/nix /mnt/nix
mount -t zfs zroot/home /mnt/home

# Mount both of the ESP's
mount /dev/sda1 /mnt/boot
mount /dev/sdc1 /mnt/boot2

echo "nixos-rebuild switch --flake github:socallinuxexpo/scale-network/rh/1702745959iso#devServer --refresh"

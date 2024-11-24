DISK0=$1
DISK1=$2

blkdiscard -f /dev/${DISK0}
blkdiscard -f /dev/${DISK1}

sgdisk -Z /dev/${DISK0}
sgdisk -Z /dev/${DISK1}

sgdisk -g -n1:1M:+512M -t1:EF00 /dev/${DISK0}

sgdisk -g -n2:0:0 -t2:BF01 /dev/${DISK0} # rest of drive

# alternative to #sfdisk --dump /dev/${DISK0} | sfdisk /dev/${DISK1}
sgdisk /dev/${DISK0} -R /dev/${DISK1}
sgdisk -G /dev/${DISK1} # Confirm with blkid

zpool create -f -O mountpoint=none -O atime=off -o ashift=12 -O acltype=posixacl -O xattr=sa -O compression=lz4 zroot mirror /dev/${DISK0}2 /dev/${DISK1}2

# Create ZFS datasets
zfs create -p -o mountpoint=legacy zroot/root      # For /
zfs snapshot zroot/root@blank
zfs create -o mountpoint=legacy zroot/home # For /home
zfs create -o mountpoint=legacy zroot/nix  # For /nix
zfs create -o mountpoint=legacy zroot/persist  # For /persist

# Create ESP partiions
# FAT32 suggested as the most compat and portable
mkfs.fat -F32 /dev/${DISK0}1
mkfs.fat -F32 /dev/${DISK1}1

# Give use labels so we dont have to lookup
# uuids or something annoying for our configs
mlabel -i /dev/${DISK0}1 ::"BOOT"
mlabel -i /dev/${DISK1}1 ::"BOOT2"

# Mount new ZFS pool
mount -t zfs zroot/root /mnt

# Create directories to mount file systems on
mkdir /mnt/{nix,home,boot,boot2}

# Mount the rest of the ZFS file systems
mount -t zfs zroot/nix /mnt/nix
mount -t zfs zroot/home /mnt/home

# Mount both of the ESP's
mount /dev/disk/by-label/BOOT /mnt/boot
mount /dev/disk/by-label/BOOT2 /mnt/boot2

echo "nixos-install --flake github:socallinuxexpo/scale-network/<branch>#<machine>"

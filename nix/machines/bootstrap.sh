#!/usr/bin/env bash

# Ref: https://gist.github.com/mx00s/ea2462a3fe6fdaa65692fe7ee824de3e
# NixOS install script synthesized from:
#
#   - Erase Your Darlings (https://grahamc.com/blog/erase-your-darlings)
#   - ZFS Datasets for NixOS (https://grahamc.com/blog/nixos-on-zfs)
#   - NixOS Manual (https://nixos.org/nixos/manual/)
#
# It expects the name of the block device (e.g. 'sda') to partition
# and install NixOS on.
#
# Example: `setup.sh sda`
#

set -euo pipefail

################################################################################

export COLOR_RESET="\033[0m"
export RED_BG="\033[41m"
export BLUE_BG="\033[44m"

# If disk provisioning goes wrong
function cleanup {
  set +e
  umount /mnt/boot
  sleep 5
  zfs destroy -r zroot
  sleep 5
  umount /zroot
  sleep 5
  zpool destroy zroot
}

function err {
    echo -e "${RED_BG}$1${COLOR_RESET}"
}

function info {
    echo -e "${BLUE_BG}$1${COLOR_RESET}"
}

################################################################################
#cleanup
#exit 10
if [[ "$EUID" > 0 ]]; then
    err "Must run as root"
    exit 1
fi

# TODO: I dont think I need this
# personal user name
export ZFS_POOL="zroot"

# ephemeral datasets
export ZFS_LOCAL="${ZFS_POOL}/local"
export ZFS_DS_ROOT="${ZFS_LOCAL}/root"
export ZFS_DS_NIX="${ZFS_LOCAL}/nix"

# persistent datasets
export ZFS_SAFE="${ZFS_POOL}/safe"
export ZFS_DS_HOME="${ZFS_SAFE}/home"
export ZFS_DS_PERSIST="${ZFS_SAFE}/persist"

export ZFS_BLANK_SNAPSHOT="${ZFS_DS_ROOT}@blank"

################################################################################
DISKS=(sda sdb sdc sdd)
for DISK in ${DISKS[@]}; do
  export DISK_PATH="/dev/${DISK}"
  if ! [[ -b "$DISK_PATH" ]]; then
    err "Invalid argument: '${DISK_PATH}' is not a block special file"
    exit 1
  fi
  info "Running the UEFI (GPT) partitioning $DISK_PATH and formatting directions from the NixOS manual ..."
  parted "$DISK_PATH" -- mklabel gpt
  parted "$DISK_PATH" -- mkpart primary ESP fat32 1MiB 512MiB
  parted "$DISK_PATH" -- mkpart primary 512MiB 100%
  parted "$DISK_PATH" -- set 1 boot on
done

export DISK_PART_BOOT="/dev/sda1"

info "Formatting boot partition ..."
mkfs.fat -F 32 -n boot "$DISK_PART_BOOT"



zpool create -f "$ZFS_POOL" mirror /dev/sda1 /dev/sdb1 mirror /dev/sdc1 /dev/sdd1

info "Enabling compression for '$ZFS_POOL' ZFS pool ..."
zfs set compression=on "$ZFS_POOL"

info "Creating '$ZFS_DS_ROOT' ZFS dataset ..."
zfs create -p -o mountpoint=legacy "$ZFS_DS_ROOT"

info "Configuring extended attributes setting for '$ZFS_DS_ROOT' ZFS dataset ..."
zfs set xattr=sa "$ZFS_DS_ROOT"

info "Configuring access control list setting for '$ZFS_DS_ROOT' ZFS dataset ..."
zfs set acltype=posixacl "$ZFS_DS_ROOT"

info "Creating '$ZFS_BLANK_SNAPSHOT' ZFS snapshot ..."
zfs snapshot "$ZFS_BLANK_SNAPSHOT"

info "Mounting '$ZFS_DS_ROOT' to /mnt ..."
mount -t zfs "$ZFS_DS_ROOT" /mnt

info "Mounting '$DISK_PART_BOOT' to /mnt/boot ..."
mkdir -p /mnt/boot
mount -t vfat "$DISK_PART_BOOT" /mnt/boot

info "Creating '$ZFS_DS_NIX' ZFS dataset ..."
zfs create -p -o mountpoint=legacy "$ZFS_DS_NIX"

info "Disabling access time setting for '$ZFS_DS_NIX' ZFS dataset ..."
zfs set atime=off "$ZFS_DS_NIX"

# Required for cntr to work
# Ref: https://github.com/Mic92/cntr/issues/108
# The key advantage of this type of xattr is improved performance.
# Storing xattrs as system attributes significantly decreases the amount of disk IO required
info "Enable posixacl and xttr=sa on ZFS dataset ..."
zfs set xattr=sa "$ZFS_DS_NIX"
zfs set acltype=posixacl "$ZFS_DS_NIX"

info "Mounting '$ZFS_DS_NIX' to /mnt/nix ..."
mkdir /mnt/nix
mount -t zfs "$ZFS_DS_NIX" /mnt/nix

info "Creating '$ZFS_DS_HOME' ZFS dataset ..."
zfs create -p -o mountpoint=legacy "$ZFS_DS_HOME"

info "Mounting '$ZFS_DS_HOME' to /mnt/home ..."
mkdir /mnt/home
mount -t zfs "$ZFS_DS_HOME" /mnt/home

info "Creating '$ZFS_DS_PERSIST' ZFS dataset ..."
zfs create -p -o mountpoint=legacy "$ZFS_DS_PERSIST"

info "Mounting '$ZFS_DS_PERSIST' to /mnt/persist ..."
mkdir /mnt/persist
mount -t zfs "$ZFS_DS_PERSIST" /mnt/persist

info "Permit ZFS auto-snapshots on ${ZFS_SAFE}/* datasets ..."
zfs set com.sun:auto-snapshot=true "$ZFS_DS_HOME"
zfs set com.sun:auto-snapshot=true "$ZFS_DS_PERSIST"

info "Creating persistent directory for host SSH keys ..."
mkdir -p /mnt/persist/etc/ssh

# Generate the hardware-configuration.nix
# Copy this file out to nixosConfigurations if hardware is new
# Otherwise flake will use its own module
# wont touch configuration.nix if it already exists
info "Generating NixOS configuration (/mnt/etc/nixos/*.nix) just in case"
nixos-generate-config --root /mnt

info "copy out the /mnt/etc/nixos/hardware-configuration.nix if new hardware"
info "nixos-install --flake github:sarcasticadmin/systems#<host>"

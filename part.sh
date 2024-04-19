#!/usr/bin/env bash

lsblk

lsblk
sudo genfstab -p /mnt >> /mnt/etc/fstab

# Check for existing drive
read -p "Enter the disk name (e.g., sda): " DISKSELECTED


# Construct the full path with /dev/ prefix
DISK="/dev/$DISKSELECTED"

if [[ ! -b "$DISK" ]]; then
  echo "Error: '$DISK' is not a valid block device."
  exit 1
fi

# Get user confirmation before proceeding
echo "This script will partition and format the entire drive '$DISK'."
echo "**WARNING:** All data on the drive will be lost. Proceed (y/N)?"
read -r confirmation

if [[ ! $confirmation =~ ^[Yy]$ ]]; then
  echo "Aborting..."
  exit 0
fi

# Define partition sizes as percentages
EFI_SIZE=512M
SWAP_SIZE=8G

# Create partitions with GPT labels
parted -a optimal "$DISK" mklabel gpt
parted -a optimal "$DISK" mkpart primary 0% ${EFI_SIZE}
parted -a optimal "$DISK" mkpart primary ${EFI_SIZE} ${SWAP_SIZE}
parted -a optimal "$DISK" mkpart primary ${SWAP_SIZE} 100%

# Assign partition names (changed line)
parted -m "$DISK" set 1 ESP  # Set the first partition as EFI

# Update partition paths with prefix
DISK_WITH_PREFIX="$DISK"
EFI_PARTITION="${DISK_WITH_PREFIX}p1"
SWAP_PARTITION="${DISK_WITH_PREFIX}p2"
ROOT_PARTITION="${DISK_WITH_PREFIX}p3"

# Format partitions
mkfs.vfat -F32 -n "EFISYSTEM" "$EFI_PARTITION"
mkswap "$SWAP_PARTITION"
swapon "$SWAP_PARTITION"  # Enable swap before formatting root
mkfs.ext4 -L "ROOT" "$ROOT_PARTITION"

echo "Partitions created successfully:"
echo "  - EFI partition: $EFI_PARTITION"
echo "  - Swap partition: $SWAP_PARTITION"
echo "  - Root partition: $ROOT_PARTITION"

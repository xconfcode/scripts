#!/bin/bash

lsblk 
# Check for existing drive
read -p "Enter the disk name (e.g., /dev/sda): " DISK

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

# Define partition sizes in sectors (modify as needed)
EFI_SIZE=512M
SWAP_SIZE=8G

# Calculate remaining space for the Linux filesystem
total_sectors=$( parted -m "$DISK" print | grep 'sectors' | awk '{print $2}' )
linux_sectors=$(( total_sectors - (EFI_SIZE + SWAP_SIZE) / 512 ))

# Create partitions
parted -m "$DISK" mklabel gpt
parted -a optimal "$DISK" mkpart primary 0% ${EFI_SIZE}
parted -a optimal "$DISK" mkpart primary ${EFI_SIZE} ${(SWAP_SIZE + EFI_SIZE)}
parted -a optimal "$DISK" mkpart primary ${(SWAP_SIZE + EFI_SIZE)} 100%

# Assign partition names
parted -m "$DISK" set 1 esp
parted -m "$DISK" set 2 swap
parted -m "$DISK" set 3 linux

# Format partitions
EFI_PARTITION="${DISK}p1"
SWAP_PARTITION="${DISK}p2"
ROOT_PARTITION="${DISK}p3"

mkfs.vfat -F32 -n "EFISYSTEM" "$EFI_PARTITION"
mkswap "$SWAP_PARTITION"
swapon "$SWAP_PARTITION"
mkfs.ext4 -L "ROOT" "$ROOT_PARTITION"

# Rest of the script remains the same... (mounting, installation, etc.)

# ...

arch-chroot /mnt sh next.sh


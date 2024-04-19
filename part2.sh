#!/bin/bash

# Script to create GPT partitions on selected disk

# Function to list available disks
list_disks() {
  local disks=()
  for disk in /dev/sd*; do
    if [[ $(fdisk -l $disk | grep 'disk label' | awk '{print $NF}') == "gpt" ]]; then
      disks+=("$disk")
    fi
  done
  if [[ ${#disks[@]} -eq 0 ]]; then
    echo "No GPT disks found."
    exit 1
  fi
  echo "Available GPT disks:"
  select disk in "${disks[@]}"; do
    if [[ $? -eq 0 ]]; then
      echo "Selected disk: $disk"
      return 0
    fi
  done
  echo "Invalid selection."
  return 1
}

# Select disk
if ! list_disks; then
  exit 1
fi
read -p "Enter the selected disk again for confirmation (e.g., /dev/sda): " disk

# Get user confirmation
read -p "WARNING: This script will erase data on the selected disk. Continue? (y/N) " -r answer
if [[ ! $answer =~ ^[Yy]$ ]]; then
  exit 0
fi

# Loop until valid partition scheme is created
while true; do
  # Clear the screen
  clear

  # Get user input for partition sizes
  read -p "Enter size (in MiB) for EFI partition (recommended: 512): " efi_size
  read -p "Enter size (in GiB) for swap partition (recommended: 8): " swap_size
  read -p "Enter remaining space percentage for Linux partition: " linux_percent

  # Calculate size for Linux partition based on user input
  total_sectors=$(fdisk -l $disk | grep 'total sectors' | awk '{print $NF}')
  linux_sectors=$(($total_sectors * $linux_percent / 100))

  # Verify user input
  if [[ -z $efi_size || -z $swap_size || -z $linux_percent ]]; then
    echo "Please enter values for all partitions."
    continue
  fi

  # Create partitions
  parted -s $disk mklabel gpt
  parted -s $disk mkpart primary 0% ${efi_size}MiB
  parted -s $disk set 1 esp on
  parted -s $disk mkpart primary ${efi_size}MiB ${((efi_size + swap_size * 1024))}MiB
  parted -s $disk set 2 swap on
  parted -s $disk mkpart primary ${((efi_size + swap_size * 1024))}MiB 100%
  parted -s $disk set 3 linux-fmt

  # Print partition table for confirmation
  parted -p $disk

  # Ask for confirmation
  read -p "Are you sure you want to create these partitions? (y/N) " -r confirm
  if [[ $confirm =~ ^[Yy]$ ]]; then
    break
  fi
done

# Inform user about next steps
echo "Partitions created successfully! Now you can format and mount them during Arch installation."
echo "Remember to label the partitions appropriately (e.g., with mkfs.fat for EFI and mkfs.ext4 for Linux)."

# Exit script
exit 0

#!/bin/bash

# Script to create GPT partitions on selected disks in Arch medium

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
  PS3="Select a disk (use number or 'all' for all disks): "
  select disk in "${disks[@]}" "all"; do
    if [[ $? -eq 0 ]]; then
      if [[ $REPLY == "all" ]]; then
        echo "Selected all disks: ${disks[@]}"
        return 0
      fi
      echo "Selected disk: $disk"
      return 0
    fi
  done
  echo "Invalid selection."
  return 1
}

# Select disks
if ! list_disks; then
  exit 1
fi
read -p "Enter selected disks again for confirmation (separate by spaces, or 'all' for all): " disks

# Function to create partitions on a disk
create_partitions() {
  local disk="$1"
  if [[ $disk == "all" ]]; then
    for disk in /dev/sd*; do
      if [[ $(fdisk -l $disk | grep 'disk label' | awk '{print $NF}') == "gpt" ]]; then
        create_partitions $disk
      fi
    done
    return
  fi

  # Get user confirmation
  read -p "WARNING: This will erase data on $disk. Continue? (y/N) " -r answer
  if [[ ! $answer =~ ^[Yy]$ ]]; then
    return
  fi

  # Create partitions
  parted -s $disk mklabel gpt
  parted -s $disk mkpart primary 0% 512MiB
  parted -s $disk set 1 esp on
  parted -s $disk mkpart primary 512MiB -  # Use remaining space for swap
  parted -s $disk set 2 swap on
  parted -s $disk mkpart primary -  # Use remaining space for Linux
  parted -s $disk set 3 linux-fmt

  # Print partition table
  parted -p $disk

  echo "Partitions created on $disk."
}

# Create partitions on selected disks
for disk in $disks; do
  create_partitions "$disk"
done

# Inform user about next steps
echo "Partitions created successfully! Now you can format and mount them during Arch installation."
echo "Remember to label the partitions appropriately (e.g., with mkfs.fat for EFI and mkfs.ext4 for Linux)."

# Exit script
exit 0

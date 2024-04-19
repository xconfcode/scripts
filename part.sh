#!/usr/bin/env bash

lsblk

# Check for existing drive
read -p "Enter the disk name (e.g., sda): " DISKSELECTED

# Validate input to ensure only disk name is entered
if [[ ! "$DISKSELECTED" =~ ^[[:alpha]]+$ ]]; then
  echo "Error: Invalid disk name. Please enter only the disk name (e.g., sda)."
  exit 1
fi

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

# Define partition sizes in sectors (modify as needed)
EFI_SIZE=$( expr 512 \* 1024 \* 1024 )  # Convert size to sectors (512 MB)
SWAP_SIZE=$( expr 8 \* 1024 \* 1024 \* 1024 )  # Convert size to sectors (8 GB)

# Create a temporary file with sfdisk commands
SFDISK_SCRIPT=$(mktemp)

cat << EOF > "$SFDISK_SCRIPT"
g  # Create a GPT partition table
n  # New partition (primary)
p  # Primary partition
1   # Partition number (1)
0%  # First sector (beginning)
${EFI_SIZE} # Last sector
n  # New partition (primary)
p  # Primary partition
2   # Partition number (2)
${EFI_SIZE} # First sector
${SWAP_SIZE} # Last sector
n  # New partition (primary)
p  # Primary partition
3   # Partition number (3)
${SWAP_SIZE} # First sector
100% # Last sector
EOF

# Run sfdisk to create partitions
sudo sfdisk "$DISK" < "$SFDISK_SCRIPT"

# Remove temporary file
rm "$SFDISK_SCRIPT"

# Assign partition names (using fdisk)
sudo fdisk -m "$DISK" << EOF
0  # Select disk
set 1 esp  # Set partition 1 as EFI
set 2 swap  # Set partition 2 as swap
set 3 linux # Set partition 3 as linux
w  # Write changes
EOF

# Rest of the script for formatting remaining partitions...

echo "Partitions created successfully."

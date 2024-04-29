#!/usr/bin/env bash

# Get user confirmation before proceeding
read -r -p "This script will install Arch Linux. Are you sure? [y/N] " response
if [[ ! $response =~ ^([Yy]$) ]]; then
  exit 0
fi

# Define helper functions
function get_partition {
  local prompt="$1"
  read -r -p "$prompt: " partition
  while [[ -z "$partition" ]]; do
    read -r -p "Invalid partition. Please enter again: " partition
  done
  echo "$partition"
}

function confirm_and_run {
  local command="$1"
  echo "Running: $command"
  read -r -p "Continue? [y/N] " response
  if [[ ! $response =~ ^([Yy]$) ]]; then
    exit 1
  fi
  eval "$command"
}

# Get partition details with error handling
EFI_PARTITION=$(get_partition "Enter EFI partition (e.g., /dev/sda1)")
SWAP_PARTITION=$(get_partition "Enter swap partition (e.g., /dev/sda2)")
ROOT_PARTITION=$(get_partition "Enter root partition (e.g., /dev/sda3)")

# Get user credentials
read -r -p "Username: " USER
read -s -p "Password: " PASSWORD
echo

# Informative messages
echo "Creating filesystems..."
echo "WARNING: Make sure you selected the correct partitions!"

# Create filesystems (use confirm_and_run for safety)
echo "Create filesystems .................!"
confirm_and_run "mkfs.fat -F32 -n \"EFISYSTEM\" \"/dev/$EFI_PARTITION\""
confirm_and_run "mkswap \"/dev/$SWAP_PARTITION\""
swapon "/dev/$SWAP_PARTITION"
confirm_and_run "mkfs.ext4 -L  \"ROOT\" \"/dev/$ROOT_PARTITION\""

# Mount target directories
echo "start mounting ...."
mount -t ext4 "/dev/$ROOT_PARTITION" /mnt
mkdir /boot/efi
mount -t fat "/dev/$EFI_PARTITION" /boot/efi

# Install base system (remove --noconfirm for manual confirmation)
echo "Installing Arch Linux base..."
pacstrap -K /mnt base linux linux-firmware sudo nano

# Script for further configuration on chrooted environment
cat << EOF > /mnt/root.sh
#!/bin/sh

useradd -m -s /bin/bash "$USER"
echo "$USER:$PASSWORD" | chpasswd
usermod -aG wheel "$USER"

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Set locale (adjust as needed)
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
hwclock --systohc
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Configure hostname and hosts file
echo "$USER" > /etc/hostname
cat << EOF > /etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	$USER
EOF

# Network and wireless tools 
# dosfstools xdg-utils xdg-user-dirs
pacstrap /mnt  grub networkmanager network-manager-applet wireless_tools wpa_supplicant dialog os-prober mtools  base-devel linux-headers bluez bluez-utils cups   openssh blueman git intel-ucode nano vim neovim  --noconfirm --needed

# wireless-tools 
pacman -S networkmanager network-manager-applet wpa_supplicant --needed --noconfirm
systemctl enable NetworkManager

# Optional packages (uncomment to install)
# pacman -S ... (list desired packages)


# Enable essential services
systemctl enable NetworkManager bluetooth cups sshd

# Bootloader installation (UEFI systems)
grub-install --target=x86_64-efi --bootloader-id=grub_uefi
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Chroot and execute configuration script
arch-chroot /mnt /bin/bash /root.sh

# Reboot message
echo "Installation complete. Reboot using 'reboot'"


#!/usr/bin/env bash

# ==========================================================================
#               [Start:: Confim]
# ==========================================================================


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
# ==========================================================================
#               [End:: Confim]
# ==========================================================================

# ==========================================================================
#               [Start:: Partition]
# ==========================================================================

# Get partition details with error handling
EFI_PARTITION=$(get_partition "Enter EFI partition (e.g., /sda1)")
SWAP_PARTITION=$(get_partition "Enter swap partition (e.g., /sda2)")
ROOT_PARTITION=$(get_partition "Enter root partition (e.g., /sda3)")

# Formatting Partion [start]
echo "Starting Formatting Partition"

 #Informative messages
echo "Creating filesystems..."
echo "WARNING: Make sure you selected the correct partitions!"

# Create filesystems (use confirm_and_run for safety)
echo "Create filesystems .................!"
confirm_and_run "mkfs.fat -F32 -n \"EFISYSTEM\" \"/dev/$EFI_PARTITION\""
confirm_and_run "mkswap \"/dev/$SWAP_PARTITION\""
swapon "/dev/$SWAP_PARTITION"
confirm_and_run "mkfs.ext4 -L  \"ROOT\" \"/dev/$ROOT_PARTITION\""
echo "Successfly Formatted Partition !!!!"

# ==========================================================================
#               [END:: Partition]
# ==========================================================================


# ==========================================================================
#               [Start :: RootPass & user]
# ==========================================================================
# Get user credentials
read -r -p "Username: " USER
read -s -p "Password: " PASSWORD
read -s -p "RootPassword: " rootpass
echo
# Get user confirmation before proceeding
read -r -p "want ad root pass? [y/N] " response
if [[ ! $response =~ ^([Yy]$) ]]; then
passwd
$roopass
  exit 0
fi
# ==========================================================================
#               [END:: RootPass & user]
# ==========================================================================



# ==========================================================================
#               [Start:: Mounting]
# ==========================================================================

# Mount target directories
echo "start mounting ...."
mount -t ext4 "/dev/$ROOT_PARTITION" /mnt
mkdir /boot/efi
mount -t fat "/dev/$EFI_PARTITION" /boot/efi
echo "Successfly Mounted & created /boot/efi directory !!!!"
# ==========================================================================
#               [END:: Mounting]
# ==========================================================================


# ==========================================================================
#               [Start:: Kernal base package]
# ==========================================================================
echo "Installing Base system into Linux kernal ......"
# Install base system (remove --noconfirm for manual confirmation)
echo "Installing Arch Linux base..."
pacstrap -K /mnt base linux linux-firmware sudo nano
 
echo "Installed successsfly  Base system into Linux kernal !!!!"
# ==========================================================================
#               [END::Kernal base package]
# ==========================================================================

# ==========================================================================
#               [Start:: chroot]
# ==========================================================================

# Generate Mount
echo " Storring mount"
genfstab -U /mnt >> /mnt/etc/fstab
echo "Successfly storred all mount"
# Creating shell script for root installaion

echo "Creating chroot script"

# Script for further configuration on chrooted environment
cat << EOF > /mnt/root.sh
#!/bin/sh

# Time
# ==========================================================================
echo " Setting Times"
ln -sf /usr/share/zoneinfo/America/New_York   /etc/localtime
echo "Successfly configure Times"
# ==========================================================================

# ==========================================================================
echo " start creating user"
useradd -m -s /bin/bash "$USER"
echo "$USER:$PASSWORD" | chpasswd
usermod -aG wheel "$USER"
echo " Successfly user created "
# ==========================================================================

# sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
# ==========================================================================
#               [Start:: generate lang]
# ==========================================================================

# Set locale (adjust as needed)
#sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

sudo sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo sed -i 's/^#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen

locale-gen
hwclock --systohc
export LANG=en_US.UTF-8
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
# ==========================================================================
#               [end:: generate lang]
# ==========================================================================

# ==========================================================================
#               [Start:: Hostname]
# ==========================================================================

echo "Configure hostname"

# Configure hostname and hosts file
echo "$USER" > /etc/hostname
cat << EOF > /etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	archpc

# ==========================================================================
#               [End:: Hostname]
# ==========================================================================

EOF
echo " HostName successfully Configure"

# ==========================================================================
#               [Start:: Installing GRUB && Depandency]
# ==========================================================================

pacman -S grub efibootmgr os-prober mtools networkmanager network-manager-applet wpa_supplicant dialog base-devel linux-headers  cups   openssh blueman git intel-ucode nano vim neovim  --needed --noconfirm
# ==========================================================================
#               [END:: Installing GRUB && Depandency]
# ==========================================================================




# ==========================================================================
#               [Start:: GRUB]
# ==========================================================================

# Bootloader installation (UEFI systems)
grub-install --target=x86_64-efi --bootloader-id=grub_uefi && grub-mkconfig -o /boot/grub/grub.cfg

# ==========================================================================
#               [End:: GRUB]
# ==========================================================================



# ==========================================================================
#               [Start:: Enabling Syetems]
# ==========================================================================

# Enable essential services
systemctl enable NetworkManager bluetooth cups sshd

# ==========================================================================
#               [End:: Enabling Syetems]
# ==========================================================================




exit 
umount -R /mnt 
Reboot


# ==========================================================================
#               [END:: chroot]
# ==========================================================================

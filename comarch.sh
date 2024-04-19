#!/usr/bin/env bash 



lsblk -l  
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



 


echo "Please enter your username" 

read USER  

 

echo "Please enter your password" 

read PASSWORD  

 

echo "Please choose Your Desktop Environment" 

echo "1. GNOME" 

echo "2. KDE" 

echo "3. XFCE" 

echo "4. NoDesktop" 

read DESKTOP 

 

# make filesystems 

echo -e "\nCreating Filesystems...\n" 

 

mkfs.vfat -F32 -n "EFISYSTEM" "${EFI}" 

mkswap "${SWAP}" 

swapon "${SWAP}" 

mkfs.ext4 -L "ROOT" "${ROOT}" 

 

# mount target 

mount -t ext4 "${ROOT}" /mnt 

mkdir /mnt/boot 

mount -t vfat "${EFI}" /mnt/boot/ 

 

echo "--------------------------------------" 

echo "-- INSTALLING Arch Linux BASE on Main Drive       --" 

echo "--------------------------------------" 

pacstrap /mnt base base-devel --noconfirm --needed 

 

# kernel 

pacstrap /mnt linux linux-firmware --noconfirm --needed 

 

echo "--------------------------------------" 

echo "-- Setup Dependencies               --" 

echo "--------------------------------------" 

 

pacstrap /mnt networkmanager network-manager-applet wireless_tools nano intel-ucode bluez bluez-utils blueman git --noconfirm --needed 

 

# fstab 

genfstab -U /mnt >> /mnt/etc/fstab 

 

echo "--------------------------------------" 

echo "-- Bootloader Installation  --" 

echo "--------------------------------------" 

bootctl install --path /mnt/boot 

echo "default arch.conf" >> /mnt/boot/loader/loader.conf 

cat <<EOF > /mnt/boot/loader/entries/arch.conf 

title Arch Linux 

linux /vmlinuz-linux 

initrd /initramfs-linux.img 

options root=${ROOT} rw 

EOF 

 

 

cat <<REALEND > /mnt/next.sh 

useradd -m $USER 

usermod -aG wheel,storage,power,audio $USER 

echo $USER:$PASSWORD | chpasswd 

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers 

 

echo "-------------------------------------------------" 

echo "Setup Language to US and set locale" 

echo "-------------------------------------------------" 

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 

locale-gen 

echo "LANG=en_US.UTF-8" >> /etc/locale.conf 

 

ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime 

hwclock --systohc 

 

echo "arch" > /etc/hostname 

cat <<EOF > /etc/hosts 

127.0.0.1	localhost 

::1			localhost 

127.0.1.1	arch.localdomain	arch 

EOF 

 

echo "-------------------------------------------------" 

echo "Display and Audio Drivers" 

echo "-------------------------------------------------" 

 

pacman -S xorg pulseaudio --noconfirm --needed 

 

systemctl enable NetworkManager bluetooth 

 

#DESKTOP ENVIRONMENT 

if [[ $DESKTOP == '1' ]] 

then  

    pacman -S gnome gdm --noconfirm --needed 

    systemctl enable gdm 

elif [[ $DESKTOP == '2' ]] 

then 

    pacman -S plasma sddm kde-applications --noconfirm --needed 

    systemctl enable sddm 

elif [[ $DESKTOP == '3' ]] 

then 

    pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --noconfirm --needed 

    systemctl enable lightdm 

else 

    echo "You have choosen to Install Desktop Yourself" 

fi 

 

echo "-------------------------------------------------" 

echo "Install Complete, You can reboot now" 

echo "-------------------------------------------------" 

 

REALEND 

 

 




arch-chroot /mnt sh next.sh


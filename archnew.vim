#!/usr/bin/env bash

echo "Please enter EFI paritition: (example /dev/sda1 or /dev/nvme0n1p1)"
read EFI

echo "Please enter SWAP paritition: (example /dev/sda2)"
read SWAP

echo "Please enter Root(/) paritition: (example /dev/sda3)"
read ROOT 

echo "Please enter your username"
read USER 

echo "Please enter your password"
read PASSWORD 


# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.fat -F32  "EFISYSTEM" "/dev/${EFI}"
mkswap "/dev/${SWAP}"
swapon "/dev/${SWAP}"
mkfs.ext4  "ROOT" "/dev/${ROOT}"

# mount target
mount -t ext4 "/dev/${ROOT}" /mnt
mkdir /mnt/boot
mount -t vfat "/dev/${EFI}" /mnt/boot/

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux BASE on Main Drive == Kernal      --"
echo "--------------------------------------"
# Kernal
pacstrap -K /mnt base linux linux-firmware  --noconfirm --needed


echo "--------------------------------------"
echo "-- Setup Dependencies               --"
echo "--------------------------------------"

# fstab
genfstab -U /mnt >> /mnt/etc/fstab


echo "--------------------------------------"
echo "-- Bootloader Installation  --"
echo "--------------------------------------"


cat <<REALEND > /mnt/root.sh
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "Setup Language to US and set locale"
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen
locale-gen

hwclock --systohc
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
export "LANG=en_US.UTF-8"

ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime

echo "archpc" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	archpc
EOF

echo "-------------------------------------------------"
echo "Display and Audio Drivers" + "and Dependancies"
echo "-------------------------------------------------"


pacman -S grub networkmanager network-manager-applet wireless_tools wpa_supplicant dialog os-prober mtools base-devel linux-headers bluez bluez-utils cups xdg-utils xdg-user-dirs  openssh blueman git intel-ucode nano vim neovim   pulseaudio  --noconfirm --needed
systemctl enable NetworkManager bluetooth cups sshd iwd

grub-install --target=x86_64-efi --bootloader-id=grub_uefi

grub-mkconfig -o /boot/grub/grub.cfg
echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"

REALEND


arch-chroot /mnt sh root.sh


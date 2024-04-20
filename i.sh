i#!/usr/bin/env bash

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

mkfs.fat -F32  "${EFI}"
mkswap "${SWAP}"
swapon "${SWAP}"
mkfs.ext4  "${ROOT}"

# mount target
#mount -t ext4 "${ROOT}" /mnt
#mkdir /mnt/boot
#mount -t vfat "${EFI}" /mnt/boot/
#mount  "${ROOT}" /mnt

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux BASE on Main Drive       --"
echo "--------------------------------------"
mount "${ROOT}" /mnt
# pacstrap /mnt base base-devel --noconfirm --needed

# kernel
pacstrap -K /mnt base linux linux-firmware nano sudo vim  --noconfirm --needed

echo "--------------------------------------"
echo "-- Setup Dependencies               --"
echo "--------------------------------------"

pacman -S nvidia nvidia-utils networkmanager network-manager-applet wireless_tools wpa_supplicant dialog  base-devel linux-headers bluez bluez-utils cups   openssh blueman git intel-ucode nano vim neovim  --noconfirm --needed
# fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "--------------------------------------"
echo "-- Bootloader Installation  --"
echo "--------------------------------------"
pacman -S grub efibootmgr os-prober mtools
mkdir /boot/efi
mount "${EFI}" /boot/efi
grub-install --target=x86_64-efi --bootloader-id=grub_uefi
grub-mkconfig -o /boot/grub/grub.cfg




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

ln -sf /usr/share/zoneinfo/Asia/Manila /etc/localtime
hwclock --systohc

echo "archpc" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	archpc.localdomain	archpc
EOF

echo "-------------------------------------------------"
echo "Display and Audio Drivers"
echo "-------------------------------------------------"

pacman -S  pulseaudio networkmanager bluez bluez-utils openssh cups iwd --noconfirm --needed

systemctl enable NetworkManager bluetooth cups sshd iwd
exit 
umount -R /mnt
echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"

REALEND


arch-chroot /mnt sh next.sh



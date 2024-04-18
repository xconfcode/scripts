#!/bin/bash

setfont ter-132b 

mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3

pacman -Syy

# ====================================================
mount /dev/sda3 
# ====================================================

pacstrap -K /mnt base linux linux-firmware nano vim sudo

genfstab -U /mnt >> /mnt/etc/fstab && cat /mnt/etc/fstab

# [Install As Root]

arch-chroot /mnt 
ln -sf /usr/share/zoneinfo/Asia/Manila /etc/localtime 


    
sed -i 'en_US.UTF-8/S/^#//' /etc/locale.gen 
sed -i '"en_US ISO-8859-1"/S/^#//' /etc/locale.gen 

locale-gen 
hwclock --systohc   

echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8 



echo archpc > /etc/hostname 
echo 127.0.0.1      localhost >> etc/hosts 
echo ::1        localhost >> etc/hosts 
echo 127.0.1.1      archpc >> etc/hosts 

# [Install Pacages ]    
pacman -S   grub networkmanager network-manager-applet wireless_tools wpa_supplicant dialog os-prober mtools efibootmgr base-devel linux-headers bluez bluez-utils cups openssh &&
# ====================================================

mkdir /boot/efi

mount /dev/sda1 /boot/efi
# ====================================================

grub-install --target=x86_64-efi --bootloader-id=grub_uefi
grub-mkconfig -o /boot/grub/grub/cfg

# [ Enabl System]

Systemctl enable NetworkManager 
Systemctl enable iwd 
Systemctl enable cups 
Systemctl enable bluetooth 
Systemctl enable sshd


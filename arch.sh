#!/usr/bin/env bash 

 

echo "Please enter EFI paritition: (example /dev/sda1 or /dev/nvme0n1p1)" 

read EFI 

# Prepend /dev/ to the user input if it doesn't already start with it 

if [[ ! "$EFI" =~ ^/dev/ ]]; then 

  EFI="/dev/$EFI" 

Fi 

 

echo "Please enter SWAP paritition: (example /dev/sda2)" 

read SWAP 

L 

echo "Please enter Root(/) paritition: (example /dev/sda3)" 

read ROOT  

 

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

 

 # pacstrap /mnt networkmanager network-manager-applet wireless_tools  bluez bluez-utils  --noconfirm --needed 
# xdg-utils xdg-user-dir
pacstrap /mnt grub iwd networkmanager network-manager-applet wireless_tools nano intel-ucode blueman git wpa_supplicant dialog os-prober mtools dosfstools base-devel linux-headers bluez  bluez-utils cups s  openssh blueman git --noconfirm --needed 
 

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

 

pacman -S  pulseaudio --noconfirm --needed 

 

systemctl enable NetworkManager bluetooth iwd bluetooth cups ssh
# Systemctl enable NetworkManager && Systemctl enable iwd && Systemctl enable bluetooth Systemctl enable cups && Systemctl enable sshd  
 


 

echo "-------------------------------------------------" 

echo "Install Complete, You can reboot now" 

echo "-------------------------------------------------" 

 

REALEND 

 

 

arch-chroot /mnt sh next.sh 

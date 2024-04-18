#!/bin/bash


mount /dev/sda2 && pacstrap -K /mnt base linux linux-firmware nano vim && genfstab -U /mnt >> /mnt/etc/fstab && cat /mnt/etc/fstab

# [Install As Root]

arch-chroot /mnt && ln -sf /usr/share/zoneinfo/Asia/Manila /etc/localtime && hwclock --systohc &&
    sed -i 'en_US.UTF-8/S/^#//' /etc/locale.gen && sed -i '"en_US ISO-8859-1"/S/^#//' /etc/locale.gen &&
    echo LANG=en_US.UTF-8 > /etc/locale.conf && export LANG=en_US.UTF-8 &&
    echo archpc > /etc/hostname &&
        echo 127.0.0.1      localhost >> etc/hosts && echo ::1      localhost >> etc/hosts &&  echo 127.0.1.1      archpc >> etc/hosts 

# [Install Pacages ]    
    pacman -S  grub grub networkmanager network-manager-applet wireless_tools wpa_supplicant dialog os-prober mtools dosfstools base-devel linux-headers bluez bluez-utils cups openssh &&
        grub-install --target=i386-pc /dev/sda && grub-mkconfig -o /boot/grub/grub/cfg

# [ Enabl System]

Systemctl enable NetworkManager && Systemctl enable iwd && Systemctl enable cups && Systemctl enable bluetooth && Systemctl enable sshd


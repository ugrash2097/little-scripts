#!/bin/bash

# Time
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
systemctl enable systemd-timesyncd
# Locale
echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
# Network
echo $1 > /etc/hostname
cat << 'EOF' > /etc/systemd/network/20-wired.network
[Match]
Name=ens18

[Link]
RequiredForOnline=routable

[Network]
DHCP=yes
EOF
systemctl enable systemd-networkd
# DNS
systemctl resolve systemd-resolved
# InitRAMFS
mkinitcpio -P
# Bootloader
pacman -S grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
# Password
echo Please set root passwd
echo then exit arch-chroot
echo then type:
echo ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

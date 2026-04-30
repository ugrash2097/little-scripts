#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

# Packages
pacman -S --noconfirm openssh grub htop vim man bat dog ltrace strace lsof syslog-ng

# Aliases
cp aliases /root/.bashrc

cat << 'EOF' > /root/.bash_profile
[[ -f ~/.bashrc ]] && source ~/.bashrc
EOF

# Time
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
systemctl enable systemd-timesyncd

# Locale
echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Network
echo $1 > /etc/hostname
cp 20-wired.network /etc/systemd/network/
systemctl enable systemd-networkd

# DNS
systemctl enable systemd-resolved

# InitRAMFS
mkinitcpio -P

# Bootloader
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# SSH
echo PermitRootLogin yes >> /etc/ssh/sshd_config
systemctl enable sshd

# Vim config
cp vimrc /root/.vimrc

# htop config
mkdir -p /root/.config/htop
cp htoprc /root/.config/htop/htoprc

# Syslog-ng
cp syslog-ng.conf /etc/syslog-ng
systemctl enable syslog-ng@default

# Messages
echo Please set root passwd
echo then exit arch-chroot
echo then type:
echo ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

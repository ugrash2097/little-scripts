#!/bin/bash

# Packages
pacman -S --noconfirm openssh grub htop vim man

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
cat << 'EOF' > /root/.vimrc
set tabstop=4
set shiftwidth=4
set expandtab
set softtabstop=4

set mouse=

syntax on
EOF

# htop config
mkdir /root/.config/htop
cat << 'EOF' > /root/.config/htop/htoprc
# Beware! This file is rewritten by htop when settings are changed in the interface.
# The parser is also very primitive, and not human-friendly.
htop_version=3.5.1-1-arch
config_reader_min_version=3
fields=0 48 17 18 38 39 130 2 46 47 49 1
hide_kernel_threads=1
hide_userland_threads=1
hide_running_in_container=0
shadow_other_users=0
show_thread_names=0
show_program_path=1
highlight_base_name=1
highlight_deleted_exe=1
shadow_distribution_path_prefix=0
highlight_megabytes=0
highlight_threads=1
highlight_changes=1
highlight_changes_delay_secs=5
find_comm_in_cmdline=1
strip_exe_from_cmdline=1
show_merged_command=1
header_margin=1
screen_tabs=1
detailed_cpu_time=0
cpu_count_from_one=0
show_cpu_smt_labels=0
show_cpu_usage=1
show_cpu_frequency=0
show_cpu_temperature=0
degree_fahrenheit=0
show_cached_memory=1
update_process_names=1
account_guest_in_cpu_meter=0
color_scheme=0
enable_mouse=0
delay=15
hide_function_bar=0
header_layout=two_50_50
column_meters_0=AllCPUs Memory Swap
column_meter_modes_0=1 1 1
column_meters_1=Tasks LoadAverage Uptime
column_meter_modes_1=2 2 2
tree_view=1
sort_key=46
tree_sort_key=0
sort_direction=-1
tree_sort_direction=1
tree_view_always_by_pid=0
all_branches_collapsed=0
screen:Main=PID USER PRIORITY NICE M_VIRT M_RESIDENT M_PRIV STATE PERCENT_CPU PERCENT_MEM TIME Command
.sort_key=PERCENT_CPU
.tree_sort_key=PID
.tree_view_always_by_pid=0
.tree_view=1
.sort_direction=-1
.tree_sort_direction=1
.all_branches_collapsed=0
screen:I/O=PID USER IO_PRIORITY IO_RATE IO_READ_RATE IO_WRITE_RATE PERCENT_SWAP_DELAY PERCENT_IO_DELAY Command
.sort_key=IO_RATE
.tree_sort_key=PID
.tree_view_always_by_pid=0
.tree_view=0
.sort_direction=-1
.tree_sort_direction=1
.all_branches_collapsed=0
EOF

# Messages
echo Please set root passwd
echo then exit arch-chroot
echo then type:
echo ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

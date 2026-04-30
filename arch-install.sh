#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

# Packages
pacman -S --noconfirm openssh grub htop vim man bat dog ltrace strace lsof syslog-ng

# Aliases
echo "alias cat=/bin/bat" >> /root/.bashrc
echo "alias ip='ip -br'" >> /root/.bashrc

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
mkdir -p /root/.config/htop
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

# Syslog-ng
cat << 'EOF' > /etc/syslog-ng/syslog-ng.conf
#############################################################################
# Default syslog-ng.conf file which collects all local logs into a
# single file called /var/log/messages.
#

@version: 4.8
@include "scl.conf"

source s_local {
	system();
	internal();
};

source s_network {
	default-network-drivers(
		# NOTE: TLS support
		#
		# the default-network-drivers() source driver opens the TLS
		# enabled ports as well, however without an actual key/cert
		# pair they will not operate and syslog-ng would display a
		# warning at startup.
		#
		#tls(key-file("/path/to/ssl-private-key") cert-file("/path/to/ssl-cert"))
	);
};

destination remote_server { udp("graylog.maison" port(514)); };

destination d_local {
	file("/var/log/messages");
	file("/var/log/messages-kv.log" template("$ISODATE $HOST $(format-welf --scope all-nv-pairs)\n") frac-digits(3));
};
destination d_acpid {
	file("/var/log/acpid.log");
};
destination d_authlog {
	file("/var/log/auth.log");
};
destination d_console {
	usertty("root");
};
destination d_cron {
	file("/var/log/crond.log");
};
destination d_daemon {
	file("/var/log/daemon.log");
};
destination d_debug {
	file("/var/log/debug.log");
};
destination d_errors {
	file("/var/log/errors.log");
};
destination d_everything {
	file("/var/log/everything.log");
};
destination d_iptables {
	file("/var/log/iptables.log");
};
destination d_kernel {
	file("/var/log/kernel.log");
};
destination d_lpr {
	file("/var/log/lpr.log");
};
destination d_mail {
	file("/var/log/mail.log");
};
destination d_messages {
	file("/var/log/messages.log");
};
destination d_news {
	file("/var/log/news.log");
};
destination d_ppp {
	file("/var/log/ppp.log");
};
destination d_syslog {
	file("/var/log/syslog.log");
};
# Log everything to tty12
destination d_tty12 {
	file("/dev/tty12");
};
destination d_user {
	file("/var/log/user.log");
};
destination d_uucp {
	file("/var/log/uucp.log");
};

filter f_acpid {
	program("acpid");
};
filter f_auth {
	facility(auth);
};
filter f_authpriv {
	facility(auth, authpriv);
};
filter f_crit {
	level(crit);
};
filter f_cron {
	facility(cron);
};
filter f_daemon {
	facility(daemon);
};
filter f_debug {
	not facility(auth, authpriv, news, mail);
};
filter f_emergency {
	level(emerg);
};
filter f_err {
	level(err);
};
filter f_everything {
	level(debug..emerg) and not facility(auth, authpriv);
};
filter f_info {
	level(info);
};
filter f_iptables {
	match("IN=" value("MESSAGE")) and match("OUT=" value("MESSAGE"));
};
filter f_kernel {
	facility(kern) and not filter(f_iptables);
};
filter f_lpr {
	facility(lpr);
};
filter f_mail {
	facility(mail);
};
filter f_messages {
	level(info..warn) and not facility(auth, authpriv, mail, news, cron) and not program(syslog-ng) and not filter(f_iptables);
};
filter f_news {
	facility(news);
};
filter f_notice {
	level(notice);
};
filter f_ppp {
	facility(local2);
};
filter f_syslog {
	program(syslog-ng);
};
filter f_user {
	facility(user);
};
filter f_uucp {
	facility(uucp);
};
filter f_warn {
	level(warn);
};

log {
	source(s_local);
	destination(remote_server);
	# uncomment this line to open port 514 to receive messages
	#source(s_network);
	# destination(d_local);
};
log {
	source(s_local);
	# filter(f_acpid);
	# destination(d_acpid);
};
log {
	source(s_local);
	# filter(f_authpriv);
	# destination(d_authlog);
};
log {
	source(s_local);
	# filter(f_cron);
	# destination(d_cron);
};
log {
	source(s_local);
	# filter(f_daemon);
	# destination(d_daemon);
};
log {
	source(s_local);
# 	filter(f_debug);
# 	destination(d_debug);
};
log {
	source(s_local);
	# filter(f_emergency);
	# destination(d_console);
};
log {
	source(s_local);
	# filter(f_err);
	# destination(d_errors);
};
log {
	source(s_local);
	# filter(f_everything);
	# destination(d_everything);
};
log {
	source(s_local);
	# filter(f_iptables);
	# destination(d_iptables);
};
log {
	source(s_local);
	# filter(f_kernel);
	# destination(d_kernel);
};
log {
	source(s_local);
	# filter(f_lpr);
	# destination(d_lpr);
};
log {
	source(s_local);
	# filter(f_mail);
	# destination(d_mail);
};
log {
	source(s_local);
	# filter(f_messages);
	# destination(d_messages);
};
log {
	source(s_local);
	# filter(f_news);
	# destination(d_news);
};
log {
	source(s_local);
	# filter(f_ppp);
	# destination(d_ppp);
};
log {
	source(s_local);
	# filter(f_user);
	# destination(d_user);
};
log {
	source(s_local);
	# filter(f_uucp);
	# destination(d_uucp);
};
log {
	source(s_local);
	# filter(f_syslog);
	# destination(d_syslog);
};
# Log everything to tty12
log {
	source(s_local);
	# destination(d_tty12);
};

options {
	chain_hostnames(off);
	create_dirs(no);
	dns_cache(no);
	flush_lines(0);
	group("log");
	keep_hostname(yes);
	log_fifo_size(10000);
	perm(0640);
	stats(freq(0));
	time_reopen(10);
	use_dns(no);
	use_fqdn(no);
};
EOF
systemctl enable syslog-ng@default

# Messages
echo Please set root passwd
echo then exit arch-chroot
echo then type:
echo ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

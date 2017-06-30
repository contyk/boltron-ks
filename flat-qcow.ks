#version=DEVEL
# Keyboard layouts
keyboard 'us'
# Root password
rootpw --plaintext redhat
# Use network installation
url --url="https://kojipkgs.stg.fedoraproject.org/compose/branched/psabata/Fedora-Modular-$releasever-20170628.n.0/compose/Server/$basearch/os/"
# System language
lang en_US.UTF-8
repo --name="fedora" --baseurl=https://kojipkgs.stg.fedoraproject.org/compose/branched/psabata/Fedora-Modular-$releasever-20170618.n.1/compose/Server/$basearch/os/
# Shutdown after installation
shutdown
# Network information
network  --bootproto=dhcp --device=link --activate
# System timezone
timezone US/Eastern
# Use text mode install
text
# System authorization information
auth --useshadow --passalgo=sha512
# Run the Setup Agent on first boot
firstboot --reconfig
# SELinux configuration
selinux --enforcing

# System bootloader configuration
bootloader --append="no_timer_check console=tty1 console=ttyS0,115200n8" --location=mbr --timeout=1
autopart --type=plain
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel --disklabel=msdos

%post

# Setup Raspberry Pi firmware
#cp -Pr /usr/share/bcm283x-firmware/* /boot/efi/
mv -f /boot/efi/config-64.txt /boot/efi/config.txt
cp -P /usr/share/uboot/rpi_3/u-boot.bin /boot/efi/rpi3-u-boot.bin

releasever=$(rpm -q --qf '%{version}\n' fedora-modular-release)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-primary
echo "Packages within this disk image"
rpm -qa
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# Disable network service here, as doing it in the services line
# fails due to RHBZ #1369794
/sbin/chkconfig network off

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

%end

%post

# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

%end

%packages --excludedocs --nocore --excludeWeakdeps
bash
coreutils-single
dhcp-client
filesystem
glibc-minimal-langpack
grubby
kernel
libcrypt
microdnf
rpm
shadow-utils
sssd-client
util-linux
-coreutils
-dosfstools
-dracut
-e2fsprogs
-fedora-logos
-fuse-libs
-gnupg2-smime
-libss
-libusbx
-pinentry
-shared-mime-info
-trousers
-xkeyboard-config

%end

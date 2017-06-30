#version=DEVEL
# Keyboard layouts
keyboard 'us'
# Root password
rootpw --iscrypted --lock locked
# Use network installation
url --url="https://kojipkgs.stg.fedoraproject.org/compose/branched/psabata/Fedora-Modular-$releasever-20170628.n.0/compose/Server/$basearch/os/"
repo --name="fedora" --baseurl=https://kojipkgs.stg.fedoraproject.org/compose/branched/psabata/Fedora-Modular-$releasever-20170628.n.0/compose/Server/$basearch/os/
# Reboot after installation
reboot
# Network information
network  --bootproto=dhcp --device=link --activate
# System timezone
timezone Etc/UTC --isUtc --nontp
# Use text mode install
text

# System bootloader configuration
bootloader --disabled
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all
# Disk partitioning information
part /boot/efi --fstype="vfat" --size=100
part / --fstype="ext4" --grow

%post --logfile /root/anaconda-post.log --erroronfail
set -eux

# Set install langs macro so that new rpms that get installed will
# only install langs that we limit it to.
LANG="en_US"
echo "%_install_langs $LANG" > /etc/rpm/macros.image-language-conf

# https://bugzilla.redhat.com/show_bug.cgi?id=1400682
echo "Import RPM GPG key"
releasever=$(rpm -q --qf '%{version}\n' fedora-modular-release)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-primary

echo "# fstab intentionally empty for containers" > /etc/fstab

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# remove some random help txt files
rm -fv usr/share/gnupg/help*.txt

# Pruning random things
rm usr/lib/rpm/rpm.daily
rm -rfv usr/lib64/nss/unsupported-tools/  # unsupported

# Statically linked crap
rm -fv usr/sbin/{glibc_post_upgrade.x86_64,sln}
ln usr/bin/ln usr/sbin/sln

# Remove some dnf info
rm -rfv /var/lib/dnf

# don't need icons
rm -rfv /usr/share/icons/*

#some random not-that-useful binaries
rm -fv /usr/bin/pinky

# we lose presets by removing /usr/lib/systemd but we do not care
rm -rfv /usr/lib/systemd

# if you want to change the timezone, bind-mount it from the host or reinstall tzdata
rm -fv /etc/localtime
mv /usr/share/zoneinfo/UTC /etc/localtime
rm -rfv  /usr/share/zoneinfo

# Final pruning
rm -rfv /var/cache/* /var/log/* /tmp/*

%end

%post --nochroot --logfile /mnt/sysimage/root/anaconda-post-nochroot.log --erroronfail
set -eux

# https://bugzilla.redhat.com/show_bug.cgi?id=1343138
# Fix /run/lock breakage since it's not tmpfs in docker
# This unmounts /run (tmpfs) and then recreates the files
# in the /run directory on the root filesystem of the container
# NOTE: run this in nochroot because "umount" does not exist in chroot
umount /mnt/sysimage/run
# The file that specifies the /run/lock tmpfile is
# /usr/lib/tmpfiles.d/legacy.conf, which is part of the systemd
# rpm that isn't included in this image. We'll create the /run/lock
# file here manually with the settings from legacy.conf
# NOTE: chroot to run "install" because it is not in anaconda env
chroot /mnt/sysimage install -d /run/lock -m 0755 -o root -g root


# See: https://bugzilla.redhat.com/show_bug.cgi?id=1051816
# NOTE: run this in nochroot because "find" does not exist in chroot
KEEPLANG=en_US
for dir in locale i18n; do
    find /mnt/sysimage/usr/share/${dir} -mindepth  1 -maxdepth 1 -type d -not \( -name "${KEEPLANG}" -o -name POSIX \) -exec rm -rfv {} +
done

%end

%packages --excludedocs --nocore --instLangs=en --excludeWeakdeps
bash
coreutils-single
fedora-modular-release
glibc-minimal-langpack
libcrypt
microdnf
rpm
shadow-utils
sssd-client
util-linux
-dosfstools
-e2fsprogs
-fuse-libs
-gnupg2-smime
-kernel
-libss
-libusbx
-pinentry
-shared-mime-info
-trousers
-xkeyboard-config

%end

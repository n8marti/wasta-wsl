#!/bin/bash

# Run this just before exporting the image.
#   Prepare a Wasta installation for imaging.
#   Ensure that default "wasta" user is created.
#   Reset the password; require it to be set on next login.

# ------------------------------------------------------------------------------
# Remove unnecessary files.
# ------------------------------------------------------------------------------
# Remove orphaned packages.
apt-get -y autoremove

# Clear out log files.
journalctl --rotate --vacuum-time=1s

# Cleaning up other unneeded files.
rm -rf /etc/apt/sources.list.d/*.save
rm -rf /var/lib/apt/lists/lock
rm -rf /var/cache/apt/archives/*
rm -rf /var/lib/ureadahead/pack
#rm -f /var/lib/update-notifier/user.d/*
#rm -f /etc/X11/xorg.conf*
#rm -f /etc/{hosts,hostname,mtab*,fstab}
if [ ! -L /etc/resolv.conf ]; then
    rm -f /etc/resolv.conf
fi
rm -f /etc/udev/rules.d/70-persistent*
rm -f /etc/cups/ssl/{server.crt,server.key}
rm -f /etc/ssh/*key*
rm -f /var/lib/dbus/machine-id
#rsync -a /dev/urandom /dev/
#find /var/log/ -type f -exec rm -f {} \;
find /var/lock/ -type f -exec rm -f {} \;
find /var/backups/ -type f -exec rm -f {} \;
find /var/tmp/ -type f -exec rm -f {} \;
find /var/crash/ -type f -exec rm -f {} \;
#find /var/lib/ubiquity/ -type f -exec rm -f {} \;
#rm -f /etc/{group,passwd,shadow,shadow-,gshadow,gshadow-}
#rm -f /etc/wicd/{wired-settings.conf,wireless-settings.conf}
#rm -rf /etc/NetworkManager/system-connections/*
rm -f /etc/printcap
rm -f /etc/cups/printers.conf
touch /etc/printcap
touch /etc/cups/printers.conf
rm -rf /var/cache/gdm/*
rm -rf /var/lib/sudo/*
rm -rf /var/lib/AccountsService/users/*
rm -rf /var/lib/kdm/*
rm -rf /var/run/console/*
#rm -f /etc/gdm/gdm.conf-custom
find /var/mail/ -type f -exec rm -f {} \;

# ------------------------------------------------------------------------------
# Ensure "Wasta" user
# ------------------------------------------------------------------------------
adduser --gecos 'Wasta,,,' --disabled-login --uid 1999 wasta
usermod -a -G adm,audio,cdrom,dialout,dip,floppy,netdev,plugdev,sudo,video wasta

# Delete the password before force-expiring it:
passwd --delete wasta
# Force password to expire immediately.
passwd --expire wasta

# ------------------------------------------------------------------------------
# Remove "Test" user if present.
# ------------------------------------------------------------------------------
if [[ -e /home/test ]]; then
    deluser --remove-home test
    rm -rf /home/test
fi

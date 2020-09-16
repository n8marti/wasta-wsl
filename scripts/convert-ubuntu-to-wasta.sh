#!/bin/bash

# ------------------------------------------------------------------------------
# Initially there is no desktop environment installed in WSL Ubuntu 20.04.
#   - Setup desktop environment
#   - Convert to Wasta
#
# The most useful setup tutorial (really!):
#   https://most-useful.com/ubuntu-20-04-desktop-gui-on-wsl-2-on-surface-pro-4/
#
# Very basic Ubuntu Wiki page:
#   https://wiki.ubuntu.com/WSL#CA-48ac1b76c2e0e391f18bb2b4dcc594fafc56d801_1
# ------------------------------------------------------------------------------

# This script needs to run with elevated privileges.

# ------------------------------------------------------------------------------
# Add systemd capability. [~50 MB]
#   Maybe not necessary, but it makes WSL act more like real Ubuntu.
# ------------------------------------------------------------------------------
# Install .Net.
wget https://https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install dotnet-runtime-3.1

# Install systemd-genie.
wget https://packagecloud.io/install/repositories/arkane-systems/wsl-translinux/script.deb.sh -O script.deb.#!/bin/sh
bash script.deb.sh
apt-get install systemd-genie
# Daemonize genie?
#   It seems to work fine without this.
#cat <<EOF > /usr/lib/genie/deviated-preverts.conf
#{
#    "daemonize": "/usr/bin/daemonize"
#}
#EOF

# Set genie to start on Windows user login.
distro="Ubuntu-20.04"
expr='s/.*\/mnt\/c\/Users\/(.*)\/AppData.*/\1/'
win_user=$(echo $PATH | sed -r "${expr}")
win_startup=/mnt/c/Users/"${win_user}"/AppData/Roaming/Microsoft/Windows/Start\ Menu/Programs/StartUp
cat <<EOF > "${win_startup}"/start-wsl-systemd-genie.bat
wsl --distribution $distro genie -i
EOF

# Start genie.
#genie -s

# ------------------------------------------------------------------------------
# Install desktop; convert to Wasta. [~1.75 GB]
# ------------------------------------------------------------------------------
# Install Wasta desktop. [~550 MB]
#apt-get install -y ubuntu-desktop
install_list="
acpi-support
aisleriot
alsa-base
alsa-utils
anacron
app-install-data-partner
apport-gtk
at-spi2-core
avahi-autoipd
avahi-daemon
baobab
bc
bluez
bluez-cups
branding-ubuntu
brltty
ca-certificates
cheese
cups
cups-bsd
cups-client
cups-filters
dirmngr
dmz-cursor-theme
eog
evince
example-content
file-roller
firefox
fonts-dejavu-core
fonts-freefont-ttf
fonts-liberation
fonts-sil-abyssinica
fonts-ubuntu
foomatic-db-compressed-ppds
fwupd
fwupdate
fwupdate-signed
gdm3
gedit
genisoimage
ghostscript-x
gir1.2-gmenu-3.0
gnome-accessibility-themes
gnome-bluetooth
gnome-calendar
gnome-control-center
gnome-disk-utility
gnome-font-viewer
gnome-getting-started-docs
gnome-initial-setup
gnome-keyring
gnome-mahjongg
gnome-menus
gnome-mines
gnome-power-manager
gnome-screenshot
gnome-session-canberra
gnome-settings-daemon
gnome-shell
gnome-shell-extension-appindicator
gnome-shell-extension-ubuntu-dock
gnome-software-plugin-snap
gnome-sudoku
gnome-terminal
gnome-todo
gpg-agent
gsettings-ubuntu-schemas
gstreamer1.0-alsa
gstreamer1.0-packagekit
gstreamer1.0-plugins-base-apps
gstreamer1.0-pulseaudio
gvfs-bin
gvfs-fuse
hplip
ibus
ibus-gtk
ibus-gtk3
ibus-table
im-config
inputattach
kerneloops
language-selector-gnome
laptop-detect
libatk-adaptor
libnotify-bin
libnss-mdns
libpam-gnome-keyring
libproxy1-plugin-gsettings
libproxy1-plugin-networkmanager
libreoffice-calc
libreoffice-gnome
libreoffice-impress
libreoffice-math
libreoffice-ogltrans
libreoffice-pdfimport
libreoffice-style-breeze
libreoffice-writer
libsasl2-modules
libu2f-udev
libwmf0.2-7-gtk
memtest86+
mousetweaks
nautilus
nautilus-sendto
nautilus-share
network-manager
network-manager-config-connectivity-ubuntu
network-manager-pptp-gnome
openprinting-ppds
orca
packagekit
pcmciautils
plymouth-theme-ubuntu-logo
policykit-desktop-privileges
ppp
pppconfig
pppoeconf
printer-driver-brlaser
printer-driver-c2esp
printer-driver-foo2zjs
printer-driver-m2300w
printer-driver-min12xxw
printer-driver-pnm2ppa
printer-driver-ptouch
printer-driver-pxljr
printer-driver-sag-gdi
printer-driver-splix
pulseaudio
pulseaudio-module-bluetooth
remmina
rfkill
rhythmbox
seahorse
shotwell
simple-scan
snapd
software-properties-gtk
speech-dispatcher
spice-vdagent
system-config-printer
thunderbird
thunderbird-gnome-support
transmission-gtk
ubuntu-artwork
ubuntu-desktop:i386
ubuntu-docs
ubuntu-drivers-common
ubuntu-release-upgrader-gtk
ubuntu-report
ubuntu-session
ubuntu-settings
ubuntu-software
ubuntu-sounds
unzip
update-manager
update-notifier
usb-creator-gtk
vino
wireless-tools
wpasupplicant
xcursor-themes
xdg-desktop-portal-gtk
xdg-user-dirs
xdg-user-dirs-gtk
xdg-utils
xkb-data
xorg
xul-ext-ubufox
yelp
zenity
zip
"
to_install=""
for p in $(echo $install_list); do
    $(dpkg --status $p &> /dev/null)
    # errno:0 = exists. errno:1 = not exists. errno:2 = invalid name (eg: with *)
    errno=$?
    if [[ $errno -eq 0 ]] || [[ $errno -eq 2 ]]; then
        to_install+=" $p "
    fi
done
apt-get install $to_install

# Remove unwanted packages.
remove_list="
blueman
dkms
fonts-thai-tlwg-otf
fonts-thai-tlwg-ttf
fonts-thai-tlwg-web
fonts-lohit-devanagari
fonts-lohit-deva-nepali
fonts-lohit-deva-marathi
fonts-samyak-orya
fonts-samyak
fonts-takao-pgothic
fonts-teluguvijayam
keepassx
landscape-client-ui-install
mpv
nemo-preview
ttf-indic-fonts-core
ttf-takao-pgothic
ttf-thai-tlwg
ttf-unfonts-core
ttf-wqy-microhei
"
to_remove=""
for p in $(echo $remove_list); do
    $(dpkg --status $p &> /dev/null)
    # errno:0 = exists. errno:1 = not exists. errno:2 = invalid name (eg: with *)
    errno=$?
    if [[ $errno -eq 0 ]] || [[ $errno -eq 2 ]]; then
        to_remove+=" $p "
    fi
done
apt-get purge $to_remove

# Install wasta-core.
add-apt-repository --yes --update ppa:wasta-linux/wasta
apt-get install --yes wasta-core-focal
apt-get update

# Install wasta-cinnamon and wasta-gnome. [~150 MB]
add-apt-repository --yes --update ppa:wasta-linux/cinnamon-4-6
apt-get install --yes wasta-cinnamon-focal wasta-gnome-focal

# Run wasta-initial-setup. [~1 GB]
wasta-initial-setup auto
# < Be sure NOT to install GRUB. >

# Configure LightDM for XDMCPServer.
cat <<EOF > /etc/lightdm/lightdm.conf.d/62-wasta-wsl.conf
[LightDM]
start-default-seat=false

[XDMCPServer]
enabled=true
port=177
EOF

# Restart lightdm.
service lightdm restart

# TODO: Fix pkexec perms for colord.

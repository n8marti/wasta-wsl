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
expr='s/.*\/mnt\/c\/Users\/(.*)\/AppData.*/\1/'
win_user=$(echo $PATH | sed -r "${expr}")
win_startup=/mnt/c/Users/"${win_user}"/Microsoft/Windows/Start\ Menu/Programs/StartUp
cat <<EOF > "${win_startup}"/start-wsl-systemd-genie.bat
start /min wsl -d Ubuntu-20.04 genie -i
EOF

# Start genie.
#genie -s

# ------------------------------------------------------------------------------
# Install desktop; convert to Wasta. [~1.75 GB]
# ------------------------------------------------------------------------------
# Install Ubuntu desktop. [~550 MB]
apt-get install -y ubuntu-desktop

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

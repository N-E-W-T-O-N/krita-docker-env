
# SPDX-FileCopyrightText: 2025 Ben Cooksley <bcooksley@kde.org>
#
# SPDX-License-Identifier: GPL-2.0-or-later
# Cleanup and shutdown
set -e
# Remove access keys
rm /home/*/.ssh/authorized_keys
# Purge all package manager caches
apt-get -qq clean
# Purge system logs as much as possible
journalctl --vacuum-time=1s
# Reseal the system for cloud-init reconfiguration
cloud-init clean --logs
truncate --size 0 /etc/machine-id
rm -f /var/lib/systemd/random-seed
echo "image" > /etc/hostname
# Trim the image to minimise it's size
# This only works properly if the system caches are dropped so do that first
echo 3 > /proc/sys/vm/drop_caches
sleep 5
fstrim -av
# All done, shutdown time
shutdown -h now

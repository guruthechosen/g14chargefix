#!/bin/sh
set -e
cd "$(dirname "$0")"
sudo install -m 755 asus-reapply-charge-limit /usr/local/bin/asus-reapply-charge-limit
sudo install -m 644 99-asus-charge-limit.rules /etc/udev/rules.d/99-asus-charge-limit.rules
sudo udevadm control --reload
echo "Installed. Unplug/replug the charger, then: journalctl -t asus-charge-limit -n 5"

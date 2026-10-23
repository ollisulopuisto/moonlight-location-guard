#!/bin/bash
# One-time, run by you: installs the root helper and a sudoers rule that lets
# your user run ONLY that helper without a password. Review before running.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
user="${SUDO_USER:-$USER}"
sudo install -d -o root -g wheel -m 755 /usr/local/libexec
sudo install -o root -g wheel -m 755 "$here/mlg-location" /usr/local/libexec/mlg-location
echo "$user ALL=(root) NOPASSWD: /usr/local/libexec/mlg-location" \
  | sudo tee /etc/sudoers.d/moonlight-location-guard >/dev/null
sudo chmod 440 /etc/sudoers.d/moonlight-location-guard
sudo visudo -cf /etc/sudoers.d/moonlight-location-guard
echo "Installed. Test: sudo /usr/local/libexec/mlg-location status"
echo "Remove: sudo rm /etc/sudoers.d/moonlight-location-guard /usr/local/libexec/mlg-location"

#!/usr/bin/env bash
# bootstrap-lxc.sh  --  Run baseline tasks once inside a CT.
# for deb container
# Usage:  bash bootstrap-lxc.sh <CTID>
#
###############################################################################
set -euo pipefail

CTID="${1:?give CTID}"
echo "[bootstrap] ➜ running once inside CT $CTID"

pct exec "$CTID" -- bash -s <<'INSIDE'
set -e
export DEBIAN_FRONTEND=noninteractive

# Skip if marker exists
MARKER=/root/.bootstrap-done
[ -f "$MARKER" ] && { echo "[bootstrap] already done"; exit 0; }

echo "[bootstrap] updating packages..."
apt-get update
apt-get -y dist-upgrade

echo "[bootstrap] locales + unattended upgrades..."
sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

apt-get -y install unattended-upgrades
systemctl enable --now unattended-upgrades

echo "[bootstrap] masking systemd-logind..."
systemctl mask --now systemd-logind.service systemd-logind.socket

touch "$MARKER"
echo "[bootstrap] ✓ done."
INSIDE

#!/usr/bin/env bash
#
# install-headscale-updater.sh
# ----------------------------
# Copy the Headscale self‑update script + systemd units into place,
# enable the timer, and run a one‑shot test.
#
# Run this **inside** the Headscale LXC as root:
#   cd /opt/infra   # ← where you cloned the repo
#   bash install/install-headscale-updater.sh
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_SRC="$REPO_ROOT/systemd/headscale/headscale-selfupdate"
UNIT_SRC_DIR="$REPO_ROOT/systemd/headscale"

[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }

# 1. Script
install -m 755 "$BIN_SRC" /usr/local/sbin/

# 2. Units
install -m 644 "$UNIT_SRC_DIR/headscale-update.service" /etc/systemd/system/
install -m 644 "$UNIT_SRC_DIR/headscale-update.timer"   /etc/systemd/system/

# 3. Deps (no‑ops if already present)
apt-get update -qq
apt-get install -y -qq jq curl sqlite3

# 4. Enable + test
systemctl daemon-reload
systemctl enable --now headscale-update.timer
systemctl start headscale-update.service   # dry run
echo "✔ Headscale updater installed. Log:"
journalctl -u headscale-update.service --no-pager -n 20

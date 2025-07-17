#!/usr/bin/env bash
# install-headscale-updater.sh
# ------------------------------------------
# Idempotent installer for:
#   * /usr/local/sbin/headscale-selfupdate
#   * headscale-update.{service,timer}
#
# Run inside the Headscale LXC as root:
#   cd /opt/proxmox-infra
#   bash install/install-headscale-updater.sh
# ------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_ROOT/systemd/headscale"

# --- sanity checks ----------------------------------------------------------
for f in headscale-selfupdate headscale-update.service headscale-update.timer; do
  [[ -f "$SRC_DIR/$f" ]] || { echo "✗ $SRC_DIR/$f not found"; exit 1; }
done
grep -q '^#!/usr/bin/env bash' "$SRC_DIR/headscale-selfupdate" \
  || { echo "✗ $SRC_DIR/headscale-selfupdate missing shebang"; exit 1; }

# --- copy files -------------------------------------------------------------
install -m 755 "$SRC_DIR/headscale-selfupdate"       /usr/local/sbin/
install -m 644 "$SRC_DIR/headscale-update.service"   /etc/systemd/system/
install -m 644 "$SRC_DIR/headscale-update.timer"     /etc/systemd/system/
install -D -m 644 "$UNIT_SRC_DIR/override.conf" /etc/systemd/system/headscale.service.d/override.conf

# --- deps -------------------------------------------------------------------
apt-get update -qq
apt-get install -y -qq jq curl sqlite3

# --- enable + dry‑run -------------------------------------------------------
systemctl daemon-reload
systemctl enable --now headscale-update.timer
systemctl restart headscale-update.service   # run once

echo "── last 10 log lines ──"
journalctl -u headscale-update.service --no-pager -n 10

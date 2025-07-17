#!/usr/bin/env bash
# idempotent installer – run inside the Headscale LXC as root
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_ROOT/systemd/headscale"

# sanity check – stop if the script is missing or wrong
if ! grep -q '^#!/usr/bin/env bash' "$SRC_DIR/headscale-selfupdate"; then
  echo "✗ headscale-selfupdate in repo is malformed (shebang missing)"; exit 1
fi

install -m 755 "$SRC_DIR/headscale-selfupdate" /usr/local/sbin/headscale-selfupdate
install -m 644 "$SRC_DIR/headscale-update.service" /etc/systemd/system/
install -m 644 "$SRC_DIR/headscale-update.timer"   /etc/systemd/system/
install -D -m 644 "$UNIT_SRC_DIR/override.conf" /etc/systemd/system/headscale.service.d/override.conf

apt-get update -qq
apt-get install -y -qq jq curl sqlite3

systemctl daemon-reload
systemctl enable --now headscale-update.timer
systemctl restart headscale-update.service   # run once

echo "── last 10 log lines ──"
journalctl -u headscale-update.service --no-pager -n 10
echo "✓ headscale-selfupdate installed and enabled"
echo "✓ headscale-update.timer enabled to run daily at 3:00 UTC"

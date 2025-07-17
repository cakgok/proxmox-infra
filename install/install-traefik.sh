#!/usr/bin/env bash
# Installs/updates latest stable Traefik v3, sets CAP_NET_BIND_SERVICE,
# and prepares /etc/traefik skeleton.
set -euo pipefail

# ── variables ────────────────────────────────────────────────────────────────
GITHUB_API="https://api.github.com/repos/traefik/traefik/releases"
ARCH=$(dpkg --print-architecture)              # amd64 | arm64 | armhf …
BIN="/usr/local/bin/traefik"
WORKDIR=$(mktemp -d)

# ── deps ─────────────────────────────────────────────────────────────────────
command -v jq >/dev/null || {
    apt-get update -qq
    apt-get install -y --no-install-recommends jq curl ca-certificates tar libcap2-bin
}

# ── latest v3 tag ────────────────────────────────────────────────────────────
TAG=$(curl -fsSL "$GITHUB_API" |
      jq -r '[ .[] | select(.draft==false and .prerelease==false)
               | .tag_name | select(test("^v3\\.")) ][0]')
VER=${TAG#v}

TAR="traefik_v${VER}_linux_${ARCH}.tar.gz"
URL="https://github.com/traefik/traefik/releases/download/${TAG}/${TAR}"
SUM="https://github.com/traefik/traefik/releases/download/${TAG}/traefik_v${VER}_checksums.txt"

# ── download + verify ────────────────────────────────────────────────────────
curl -Lso "$WORKDIR/$TAR" "$URL"
curl -Lso "$WORKDIR/checksums.txt" "$SUM"
(cd "$WORKDIR" && sha256sum -c --ignore-missing checksums.txt)

# ── install ──────────────────────────────────────────────────────────────────
tar -xzf "$WORKDIR/$TAR" -C "$WORKDIR" traefik
install -m 755 "$WORKDIR/traefik" "$BIN"

# give low‑port capability
setcap 'cap_net_bind_service=+ep' "$BIN"

# skeleton dirs & user
useradd --system --home /etc/traefik --shell /usr/sbin/nologin traefik 2>/dev/null || true
install -d -o traefik -g traefik /etc/traefik/dynamic /var/log/traefik

echo "✓ Traefik $VER installed to $BIN"

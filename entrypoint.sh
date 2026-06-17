#!/bin/bash
# Runtime entrypoint for the Dante SOCKS5 proxy container.
# Generates /etc/danted.conf at CONTAINER START (not at build time), because
# the network interface name inside a running container on Koyeb/Render/
# JustRunMy.App/Docker can differ from the build environment. Hardcoding
# "eth0" at build time is what was causing the proxy to fail to start on
# some platforms with an error like:
#   ioctl: SIOCGIFINDEX: No such device
set -e

PROXY_USER="${PROXY_USER:-meow}"
PROXY_PASS="${PROXY_PASS:-meow}"
PROXY_PORT="${PROXY_PORT:-1080}"

echo "[*] Detecting network interface..."
IFACE="$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}')"
if [ -z "$IFACE" ]; then
    # No default route found (happens in some sandboxed containers) — fall
    # back to the first non-loopback interface we can find.
    IFACE="$(ip -o link show 2>/dev/null | awk -F': ' '$2 != "lo" {print $2; exit}')"
fi
IFACE="${IFACE:-eth0}"
echo "[*] Using interface: $IFACE"

echo "[*] Setting up proxy user: $PROXY_USER"
if id "$PROXY_USER" >/dev/null 2>&1; then
    echo "${PROXY_USER}:${PROXY_PASS}" | chpasswd
else
    useradd -r -s /usr/sbin/nologin "$PROXY_USER"
    echo "${PROXY_USER}:${PROXY_PASS}" | chpasswd
fi

echo "[*] Writing /etc/danted.conf..."
cat > /etc/danted.conf <<EOF
logoutput: stderr
user.privileged: root
user.unprivileged: nobody

internal: 0.0.0.0 port = ${PROXY_PORT}
external: ${IFACE}

socksmethod: username
clientmethod: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    socksmethod: username
    log: connect disconnect
}
EOF

echo "=============================="
echo " SOCKS5 PROXY STARTING"
echo " Port : ${PROXY_PORT}"
echo " User : ${PROXY_USER}"
echo "=============================="

exec danted -f /etc/danted.conf

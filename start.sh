# SOCKS5 Proxy Setup — dante-server
# User: meow | Pass: meow | Port: 1080
# Run as root or with sudo

set -e

PROXY_USER="meow"
PROXY_PASS="meow"
PROXY_PORT="1080"

echo "[*] Detecting network interface..."
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
echo "[*] Using interface: $IFACE"

echo "[*] Installing dante-server..."
apt update -qq && apt install -y dante-server

echo "[*] Creating proxy user: $PROXY_USER"
if id "$PROXY_USER" &>/dev/null; then
    echo "[*] User already exists, updating password..."
else
    useradd -r -s /usr/sbin/nologin "$PROXY_USER"
fi
echo "$PROXY_USER:$PROXY_PASS" | chpasswd

echo "[*] Writing /etc/danted.conf..."
cat > /etc/danted.conf <<EOF
logoutput: syslog
user.privileged: root
user.unprivileged: nobody

internal: 0.0.0.0 port = $PROXY_PORT
external: $IFACE

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

echo "[*] Enabling & starting danted..."
systemctl enable danted
systemctl restart danted
systemctl status danted --no-pager

echo "[*] Opening firewall port $PROXY_PORT..."
if command -v ufw &>/dev/null; then
    ufw allow "$PROXY_PORT"/tcp
    echo "[*] ufw rule added"
fi

PUBLIC_IP=$(curl -s https://ifconfig.me || echo "unknown")
echo ""
echo "=============================="
echo " SOCKS5 PROXY READY"
echo " Host : $PUBLIC_IP"
echo " Port : $PROXY_PORT"
echo " User : $PROXY_USER"
echo " Pass : $PROXY_PASS"
echo "=============================="

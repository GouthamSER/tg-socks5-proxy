# tg-socks5-proxy

<b><i>Run In Vps :)</i></b><br>

A minimal SOCKS5 proxy built on [Dante](https://www.inet.no/dante/) (`danted`), intended for use as a Telegram proxy (Settings → Data and Storage → Proxy Settings → SOCKS5) or as an outbound proxy inside your own Telegram bot/userbot code (Pyrogram, Hydrogram, Telethon, etc.).

## What's in this repo

| File | Purpose |
|---|---|
| `start.sh` | One-shot installer for a bare Linux VPS (Ubuntu/Debian, systemd) — no Docker needed |

---

## ⚠️ Before you deploy anywhere public

The default credentials are `meow` / `meow`. Anyone who finds your host:port can use your proxy and bandwidth if you don't change this. Set your own `PROXY_USER` / `PROXY_PASS` (see below) before exposing this on the internet.


## Method 1 — Plain Linux VPS (Ubuntu/Debian)

For DigitalOcean, Hetzner, AWS, Oracle Cloud, or any VPS with systemd:

```bash
git clone https://github.com/GouthamSER/tg-socks5-proxy
cd tg-socks5-proxy
chmod +x start.sh

# defaults (meow/meow, port 1080)
sudo bash start.sh

# or with your own credentials/port
sudo bash start.sh myuser mypassword 1080
If using Dante (danted):
sudo systemctl stop danted (to stop)
```

The script installs Dante, creates the proxy user, writes the config, opens the port in `ufw` if present, and prints your connection details (including your VPS's public IP) at the end.

---

**Important caveat:** SOCKS5 is a raw TCP protocol, not HTTP. Many beginner-friendly PaaS platforms (Render's Web Services, and JustRunMy.App's standard port mapping at the time of writing) only forward **HTTP/HTTPS** traffic on the public port they give you — a raw TCP SOCKS5 connection won't get through even though the container is running fine internally. Before relying on one of these for public access, check the provider's docs for an explicit "TCP proxy" / "raw TCP port" option. If that's not available, use Koyeb's TCP Proxy or a plain VPS instead — both are confirmed to support raw TCP.


## Connecting Telegram to the proxy

In the Telegram app: **Settings → Data and Storage → Proxy Settings → Add Proxy → Use SOCKS5**, then enter the host, port, username, and password from your deployment.

For bot/userbot code (e.g. Pyrogram/Hydrogram), pass it as a SOCKS5 proxy config, for example:

```python
proxy = dict(
    scheme="socks5",
    hostname="your-host",
    port=1080,
    username="myuser",
    password="mypassword",
)
```

## Testing the proxy

```bash
curl -x socks5://myuser:mypassword@your-host:1080 https://ifconfig.me
```

If this returns an IP address, the proxy is working.


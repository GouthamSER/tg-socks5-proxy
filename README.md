# Telegram SOCKS5 Proxy (Dante)

A minimal SOCKS5 proxy built on [Dante](https://www.inet.no/dante/) (`danted`), intended for use as a Telegram proxy (Settings → Data and Storage → Proxy Settings → SOCKS5) or as an outbound proxy inside your own Telegram bot/userbot code (Pyrogram, Hydrogram, Telethon, etc.).

## What's in this repo

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the container image for Koyeb / JustRunMy.App / Render / any Docker host |
| `entrypoint.sh` | Runs at **container start** — detects the real network interface and writes `danted.conf` |
| `start.sh` | One-shot installer for a bare Linux VPS (Ubuntu/Debian, systemd) — no Docker needed |

### What was fixed from the original version

The original `Dockerfile` baked a static `external: eth0` line into `danted.conf` **at build time**. On some container platforms the runtime network interface isn't named `eth0`, which makes `danted` fail to start with an error like `ioctl: SIOCGIFINDEX: No such device`. This version moves config generation into `entrypoint.sh`, which runs when the container actually starts and auto-detects the correct interface (falling back to `eth0` only if detection fails). It also makes the username/password/port configurable via environment variables instead of being hardcoded, and `start.sh` now has a proper shebang, a root check, and accepts custom credentials.

---

## ⚠️ Before you deploy anywhere public

The default credentials are `meow` / `meow`. Anyone who finds your host:port can use your proxy and bandwidth if you don't change this. Set your own `PROXY_USER` / `PROXY_PASS` (see below) before exposing this on the internet.

---

## Method 1 — Koyeb (recommended for free 24/7 hosting)

Koyeb has a **TCP Proxy** feature, which is what makes a raw SOCKS5 service reachable from outside Koyeb's network.

1. Create a new App on [Koyeb](https://app.koyeb.com/) and connect this repository (or upload these files directly).
2. Make sure the **Builder** is set to build from the `Dockerfile`.
3. In the **Ports** section, set the port to `1080`.
4. Enable **TCP Proxy** for that port (this is the important step — without it, the port behaves like HTTP and SOCKS5 traffic won't pass through).
5. (Optional) Add environment variables `PROXY_USER`, `PROXY_PASS`, `PROXY_PORT` to override the defaults.
6. Deploy.

Once the app is "Healthy", Koyeb gives you a public hostname and a separate public TCP port — those go into your Telegram client/bot, not port 1080 itself.

* **Server:** `<your-app-name>.koyeb.app`
* **Port:** the public TCP port Koyeb assigns (shown in the dashboard)
* **Username / Password:** whatever you set in `PROXY_USER` / `PROXY_PASS`

---

## Method 2 — Plain Linux VPS (Ubuntu/Debian)

For DigitalOcean, Hetzner, AWS, Oracle Cloud, or any VPS with systemd:

```bash
git clone <your-repo-url>
cd <your-repo-folder>
chmod +x start.sh

# defaults (meow/meow, port 1080)
sudo bash start.sh

# or with your own credentials/port
sudo bash start.sh myuser mypassword 1080
```

The script installs Dante, creates the proxy user, writes the config, opens the port in `ufw` if present, and prints your connection details (including your VPS's public IP) at the end.

---

## Method 3 — Any other Docker host (JustRunMy.App, Render, Railway, Fly.io, your own server, etc.)

```bash
docker build -t tg-socks5-proxy .
docker run -d -p 1080:1080 \
  -e PROXY_USER=myuser \
  -e PROXY_PASS=mypassword \
  -e PROXY_PORT=1080 \
  tg-socks5-proxy
```

**Important caveat:** SOCKS5 is a raw TCP protocol, not HTTP. Many beginner-friendly PaaS platforms (Render's Web Services, and JustRunMy.App's standard port mapping at the time of writing) only forward **HTTP/HTTPS** traffic on the public port they give you — a raw TCP SOCKS5 connection won't get through even though the container is running fine internally. Before relying on one of these for public access, check the provider's docs for an explicit "TCP proxy" / "raw TCP port" option. If that's not available, use Koyeb's TCP Proxy or a plain VPS instead — both are confirmed to support raw TCP.

---

## Environment variables (Docker / Koyeb / JustRunMy.App)

| Variable | Default | Description |
|---|---|---|
| `PROXY_USER` | `meow` | SOCKS5 username |
| `PROXY_PASS` | `meow` | SOCKS5 password |
| `PROXY_PORT` | `1080` | Port `danted` listens on inside the container |

---

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

## Troubleshooting

* **`ioctl: SIOCGIFINDEX: No such device`** — the interface name danted was told to use doesn't exist on that host. This is fixed by `entrypoint.sh` in this version (it auto-detects the interface); make sure you're running the updated `Dockerfile`/`entrypoint.sh` together, not mixing the old `Dockerfile` with the new files.
* **Connection refused from outside** — on Koyeb, confirm **TCP Proxy** is enabled on the port; on Render/JustRunMy.App, confirm the platform actually forwards raw TCP (see Method 3 caveat above).
* **Authentication failed in Telegram** — double-check `PROXY_USER`/`PROXY_PASS` match exactly what you set as environment variables (they're case-sensitive).

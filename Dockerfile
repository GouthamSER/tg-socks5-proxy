FROM debian:bullseye-slim

# dante-server  -> the SOCKS5 daemon (danted)
# iproute2      -> provides `ip`, used by entrypoint.sh to detect the real
#                  network interface at container start (fixes builds that
#                  hardcoded "eth0", which doesn't always exist on
#                  Koyeb/Render/JustRunMy.App/other container runtimes)
RUN apt-get update && \
    apt-get install -y --no-install-recommends dante-server iproute2 && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default credentials/port — override these from your host's dashboard
# (Koyeb/Render/JustRunMy.App env var settings) or with `docker run -e`.
# Change the default password before deploying anywhere public.
ENV PROXY_USER=meow \
    PROXY_PASS=meow \
    PROXY_PORT=1080

EXPOSE 1080

ENTRYPOINT ["/entrypoint.sh"]

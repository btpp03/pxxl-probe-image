#!/bin/sh
# Pxxl web-service wrapper.
#  - a tiny HTTP responder on $PORT (and :80) satisfies the platform health check
#  - the official Nezha v2 agent runs as an outbound gRPC client, no inbound port
set -u

SERVER="${NZ_SERVER:-}"
SECRET="${NZ_CLIENT_SECRET:-}"
if [ -z "$SERVER" ] || [ -z "$SECRET" ]; then
    echo "FATAL: NZ_SERVER / NZ_CLIENT_SECRET missing" >&2
    exit 1
fi

# The official installer writes "server: host" (no port) which falls back to a
# non-443 port; this panel is only reachable on 443 through Cloudflare.
case "$SERVER" in
    *:*) S="$SERVER" ;;
    *)   S="${SERVER}:443" ;;
esac

# Stable instance id: rebuilding the container must not create a new server row.
U="$(printf '%s' "$SECRET" | sha256sum | awk '{h=$1; printf "%s-%s-4%s-a%s-%s", substr(h,1,8), substr(h,9,4), substr(h,13,3), substr(h,16,3), substr(h,19,12)}')"

cat > /opt/probe/config.yml <<EOF
client_secret: ${SECRET}
debug: true
disable_auto_update: true
disable_command_execute: true
disable_force_update: true
insecure_tls: false
report_delay: 3
server: ${S}
tls: true
uuid: ${U}
EOF
chmod 0600 /opt/probe/config.yml

(
    # The agent lets NZ_* env vars override config.yml scalars. Keep the
    # normalized config authoritative by dropping the raw inputs first.
    unset NZ_SERVER NZ_CLIENT_SECRET NZ_TLS NZ_UUID \
          NZ_DISABLE_AUTO_UPDATE NZ_DISABLE_FORCE_UPDATE \
          NZ_DISABLE_COMMAND_EXECUTE NZ_SKIP_CONNECTION_COUNT
    while true; do
        echo "[probe] agent start"
        /opt/probe/nezha-agent -c /opt/probe/config.yml 2>&1
        echo "[probe] agent exited, retry in 30s"
        sleep 30
    done
) &

P="${PORT:-80}"
if [ "$P" != "80" ]; then
    httpd -f -p 0.0.0.0:80 -h /opt/probe/www >/dev/null 2>&1 &
fi
echo "[probe] health responder on 0.0.0.0:${P}"
exec httpd -f -p "0.0.0.0:${P}" -h /opt/probe/www

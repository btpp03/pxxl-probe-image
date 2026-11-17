FROM alpine:3.20

# Official Nezha v2 agent binary, pinned into the image at build time.
# Runtime auto-update is disabled in config.yml, so the image is the version.
ARG TARGETARCH
RUN apk add --no-cache curl unzip ca-certificates \
 && case "$TARGETARCH" in \
      arm64) A=arm64 ;; \
      arm)   A=arm64 ;; \
      *)     A=amd64 ;; \
    esac \
 && mkdir -p /opt/probe/www \
 && curl -fsSL --max-time 180 "https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_${A}.zip" -o /tmp/agent.zip \
 && unzip -qo /tmp/agent.zip -d /opt/probe \
 && chmod 0755 /opt/probe/nezha-agent \
 && rm -f /tmp/agent.zip \
 && apk del curl unzip \
 && printf 'ok\n' > /opt/probe/www/index.html

COPY entrypoint.sh /opt/probe/entrypoint.sh
RUN chmod 0755 /opt/probe/entrypoint.sh

ENV PORT=80
EXPOSE 80
ENTRYPOINT ["/bin/sh", "/opt/probe/entrypoint.sh"]

FROM ghcr.io/openclaw/openclaw:latest

# Copy entrypoint to home dir (writable by node user) with exec permission
COPY --chmod=755 entrypoint-patch.sh /home/node/entrypoint-patch.sh

# Override the entrypoint
ENTRYPOINT ["/home/node/entrypoint-patch.sh"]

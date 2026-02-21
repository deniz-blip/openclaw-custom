FROM ghcr.io/openclaw/openclaw:latest

# Copy our custom entrypoint that patches dmPolicy after config generation
COPY entrypoint-patch.sh /usr/local/bin/entrypoint-patch.sh
RUN chmod +x /usr/local/bin/entrypoint-patch.sh

# Override the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint-patch.sh"]

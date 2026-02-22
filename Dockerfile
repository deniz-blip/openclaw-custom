FROM ghcr.io/openclaw/openclaw:latest

# Copy entrypoint (already executable via git)
COPY entrypoint-patch.sh /home/node/entrypoint-patch.sh
COPY credit-proxy.mjs /home/node/credit-proxy.mjs

ENTRYPOINT ["/home/node/entrypoint-patch.sh"]

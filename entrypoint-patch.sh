#!/bin/sh
set -e

# Run the original Docker entrypoint if it exists (generates openclaw.json)
if [ -f /docker-entrypoint.sh ]; then
  echo "[patch] Running original entrypoint..."
  # Source it to get config generated (don't exec, we need control after)
  /docker-entrypoint.sh true 2>/dev/null || true
fi

# Wait briefly for config to be generated
sleep 2

# Patch the openclaw.json to set dmPolicy to open
CONFIG_FILE="$HOME/.openclaw/openclaw.json"
echo "[patch] Looking for config at $CONFIG_FILE"

if [ -f "$CONFIG_FILE" ]; then
  echo "[patch] Config found, patching dmPolicy..."
  node -e "
    var fs = require('fs');
    var p = '$CONFIG_FILE';
    try {
      var c = JSON.parse(fs.readFileSync(p, 'utf8'));
      c.channels = c.channels || {};
      c.channels.telegram = c.channels.telegram || {};
      c.channels.telegram.dmPolicy = 'open';
      fs.writeFileSync(p, JSON.stringify(c, null, 2));
      console.log('[patch] dmPolicy set to open successfully');
    } catch(e) {
      console.error('[patch] Failed:', e.message);
    }
  "
else
  echo "[patch] Config not found yet, will be created by gateway"
fi

# Start the gateway
echo "[patch] Starting OpenClaw gateway..."
exec node openclaw.mjs gateway --allow-unconfigured

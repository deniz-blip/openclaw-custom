#!/bin/sh
set -e

echo "[clawoop] === Custom OpenClaw Entrypoint ==="
echo "[clawoop] Using openclaw CLI to configure dmPolicy=open"

# Step 1: Run onboard to initialize telegram channel config
echo "[clawoop] Step 1: Running openclaw onboard..."
node openclaw.mjs onboard --channel=telegram --token="$TELEGRAM_BOT_TOKEN" 2>&1 || true

# Step 2: Set the FULL telegram channel config with dmPolicy=open via CLI
echo "[clawoop] Step 2: Setting channels.telegram config via CLI..."
node openclaw.mjs config set --json channels.telegram "{\"enabled\":true,\"dmPolicy\":\"open\",\"botToken\":\"$TELEGRAM_BOT_TOKEN\",\"allowFrom\":[\"*\"]}" 2>&1 || true

# Step 3: Also set the AI provider config
echo "[clawoop] Step 3: Setting AI provider config..."
if [ -n "$ANTHROPIC_API_KEY" ]; then
  node openclaw.mjs config set ai.provider "${AI_PROVIDER:-anthropic}" 2>&1 || true
  node openclaw.mjs config set ai.model "${AI_MODEL:-claude-opus-4-20250514}" 2>&1 || true
  node openclaw.mjs config set --json ai.credentials "{\"anthropicApiKey\":\"$ANTHROPIC_API_KEY\"}" 2>&1 || true
fi

# Step 4: Run openclaw doctor --fix to apply any remaining fixes
echo "[clawoop] Step 4: Running doctor --fix..."
node openclaw.mjs doctor --fix 2>&1 || true

# Step 5: Start the gateway
echo "[clawoop] Step 5: Starting gateway..."
exec node openclaw.mjs gateway --allow-unconfigured

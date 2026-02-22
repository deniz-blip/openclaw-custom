#!/bin/sh
set -e

echo "[clawoop] === Custom OpenClaw Entrypoint ==="
echo "[clawoop] Platform: ${PLATFORM:-telegram}"

# Step 1: Onboard the correct channel
echo "[clawoop] Step 1: Running openclaw onboard..."
if [ "$PLATFORM" = "slack" ]; then
  node openclaw.mjs onboard --channel=slack --token="$SLACK_BOT_TOKEN" 2>&1 || true
elif [ "$PLATFORM" = "discord" ]; then
  node openclaw.mjs onboard --channel=discord --token="$DISCORD_BOT_TOKEN" 2>&1 || true
else
  node openclaw.mjs onboard --channel=telegram --token="$TELEGRAM_BOT_TOKEN" 2>&1 || true
fi

# Step 2: Set channel config with dmPolicy=open via CLI
echo "[clawoop] Step 2: Setting channel config via CLI..."
if [ "$PLATFORM" = "slack" ]; then
  node openclaw.mjs config set --json channels.slack "{\"enabled\":true,\"dmPolicy\":\"open\",\"botToken\":\"$SLACK_BOT_TOKEN\",\"allowFrom\":[\"*\"]}" 2>&1 || true
elif [ "$PLATFORM" = "discord" ]; then
  node openclaw.mjs config set --json channels.discord "{\"enabled\":true,\"dmPolicy\":\"open\",\"botToken\":\"$DISCORD_BOT_TOKEN\",\"allowFrom\":[\"*\"]}" 2>&1 || true
else
  node openclaw.mjs config set --json channels.telegram "{\"enabled\":true,\"dmPolicy\":\"open\",\"botToken\":\"$TELEGRAM_BOT_TOKEN\",\"allowFrom\":[\"*\"]}" 2>&1 || true
fi

# Step 3: Also set the AI provider config
echo "[clawoop] Step 3: Setting AI provider config..."
if [ -n "$ANTHROPIC_API_KEY" ]; then
  node openclaw.mjs config set ai.provider "${AI_PROVIDER:-anthropic}" 2>&1 || true
  node openclaw.mjs config set ai.model "${AI_MODEL:-claude-opus-4-20250514}" 2>&1 || true
  node openclaw.mjs config set --json ai.credentials "{\"anthropicApiKey\":\"$ANTHROPIC_API_KEY\"}" 2>&1 || true
fi

# Step 4: Configure Google OAuth for gog tool (Calendar, Gmail, Drive)
echo "[clawoop] Step 4: Configuring Google services..."
if [ -n "$GOG_REFRESH_TOKEN" ] && [ -n "$GOOGLE_OAUTH_CLIENT_ID" ]; then
  echo "[clawoop]   Google OAuth token found — setting up gog tool..."

  # Create credentials.json for Google OAuth
  cat > /home/node/google-credentials.json <<CRED_EOF
{
  "installed": {
    "client_id": "$GOOGLE_OAUTH_CLIENT_ID",
    "client_secret": "$GOOGLE_OAUTH_CLIENT_SECRET",
    "redirect_uris": ["urn:ietf:wg:oauth:2.0:oob"],
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token"
  }
}
CRED_EOF

  # Configure gogcli to use file-based keyring (works in containers)
  export GOG_KEYRING_BACKEND="${GOG_KEYRING_BACKEND:-file}"
  export GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD:-clawoop-default}"

  # Load credentials into gogcli
  if command -v gogcli >/dev/null 2>&1; then
    gogcli load-credentials /home/node/google-credentials.json 2>&1 || true
    # Inject the refresh token directly
    gogcli set-token --refresh-token="$GOG_REFRESH_TOKEN" 2>&1 || true
    echo "[clawoop]   gogcli configured with user's Google token"
  else
    echo "[clawoop]   gogcli not found — setting env vars for gog tool"
  fi

  # Enable Google tools in OpenClaw config
  node openclaw.mjs config set --json tools.gog '{"enabled":true}' 2>&1 || true
  
  # Set the Google credentials path
  export GOOGLE_APPLICATION_CREDENTIALS=/home/node/google-credentials.json

  echo "[clawoop]   Google services configured for: ${GOG_CONNECTED_EMAIL:-unknown}"
else
  echo "[clawoop]   No Google OAuth token — skipping gog tool setup"
fi

# Step 4b: Configure Notion
if [ -n "$NOTION_API_KEY" ]; then
  echo "[clawoop]   Notion token found — enabling notion skill..."
  echo "NOTION_API_KEY=$NOTION_API_KEY" >> /home/node/.openclaw/.env
  echo "[clawoop]   Notion configured"
fi

# Step 4c: Configure GitHub
if [ -n "$GITHUB_TOKEN" ]; then
  echo "[clawoop]   GitHub token found — enabling github skill..."
  echo "GITHUB_TOKEN=$GITHUB_TOKEN" >> /home/node/.openclaw/.env
  echo "[clawoop]   GitHub configured"
fi

# Step 4d: Configure Spotify
if [ -n "$SPOTIFY_CLIENT_ID" ] && [ -n "$SPOTIFY_CLIENT_SECRET" ]; then
  echo "[clawoop]   Spotify credentials found — enabling spotify skill..."
  echo "SPOTIFY_CLIENT_ID=$SPOTIFY_CLIENT_ID" >> /home/node/.openclaw/.env
  echo "SPOTIFY_CLIENT_SECRET=$SPOTIFY_CLIENT_SECRET" >> /home/node/.openclaw/.env
  echo "[clawoop]   Spotify configured"
fi

# Step 4e: Configure Trello
if [ -n "$TRELLO_API_KEY" ] && [ -n "$TRELLO_TOKEN" ]; then
  echo "[clawoop]   Trello credentials found — enabling trello skill..."
  echo "TRELLO_API_KEY=$TRELLO_API_KEY" >> /home/node/.openclaw/.env
  echo "TRELLO_TOKEN=$TRELLO_TOKEN" >> /home/node/.openclaw/.env
  echo "[clawoop]   Trello configured"
fi

# Step 4f: Configure Twitter/X
if [ -n "$X_API_KEY" ] && [ -n "$X_ACCESS_TOKEN" ]; then
  echo "[clawoop]   Twitter/X credentials found — enabling x-api skill..."
  mkdir -p /home/node/.openclaw/secrets
  cat > /home/node/.openclaw/secrets/x-api.json <<X_EOF
{
  "api_key": "$X_API_KEY",
  "api_secret": "$X_API_SECRET",
  "access_token": "$X_ACCESS_TOKEN",
  "access_secret": "$X_ACCESS_SECRET"
}
X_EOF
  echo "[clawoop]   Twitter/X configured"
fi

# Step 4g: Configure Home Assistant
if [ -n "$HA_URL" ] && [ -n "$HA_TOKEN" ]; then
  echo "[clawoop]   Home Assistant credentials found — enabling HA skill..."
  echo "HA_URL=$HA_URL" >> /home/node/.openclaw/.env
  echo "HA_TOKEN=$HA_TOKEN" >> /home/node/.openclaw/.env
  echo "[clawoop]   Home Assistant configured"
fi

# Step 5: Configure JIT Authorization System Prompt
echo "[clawoop] Step 5: Configuring JIT authorization prompt..."

# Build list of connected services
CONNECTED_SERVICES=""
[ -n "$GOG_REFRESH_TOKEN" ] && CONNECTED_SERVICES="${CONNECTED_SERVICES}Google Workspace (Calendar, Gmail, Drive), "
[ -n "$NOTION_API_KEY" ] && CONNECTED_SERVICES="${CONNECTED_SERVICES}Notion, "
[ -n "$GITHUB_TOKEN" ] && CONNECTED_SERVICES="${CONNECTED_SERVICES}GitHub, "
[ -n "$SPOTIFY_CLIENT_ID" ] && CONNECTED_SERVICES="${CONNECTED_SERVICES}Spotify, "
[ -n "$TRELLO_API_KEY" ] && CONNECTED_SERVICES="${CONNECTED_SERVICES}Trello, "
[ -n "$X_API_KEY" ] && CONNECTED_SERVICES="${CONNECTED_SERVICES}Twitter/X, "
[ -n "$HA_URL" ] && CONNECTED_SERVICES="${CONNECTED_SERVICES}Home Assistant, "

# Remove trailing comma
CONNECTED_SERVICES=$(echo "$CONNECTED_SERVICES" | sed 's/, $//')

if [ -z "$CONNECTED_SERVICES" ]; then
  CONNECTED_SERVICES="None connected yet"
fi

# Write system prompt addition to a file the bot can read
cat > /home/node/.openclaw/jit-prompt.md <<PROMPT_EOF
## Connected Services
The user has connected these services: ${CONNECTED_SERVICES}.

## Service Connection Guide
If the user asks you to do something that requires a service they haven't connected, politely tell them:
- What service is needed
- Send them this link to connect it: https://clawoop.com?connect=SERVICE_ID

Use these exact service IDs in the link:
- google (Google Calendar, Gmail, Drive)
- notion (Notion pages and databases)
- github (GitHub repos, issues, PRs)
- spotify (Music playback and playlists)
- trello (Kanban boards and tasks)
- twitter (Post tweets, reply, search)
- homeassistant (Smart home control)

Example: "To manage your calendar, you'll need to connect Google Workspace first. Click here to connect: https://clawoop.com?connect=google"

Do NOT attempt to use a service that isn't connected — always guide the user to connect it first.
PROMPT_EOF

echo "[clawoop]   JIT prompt configured. Connected: ${CONNECTED_SERVICES}"

# Step 6: Run openclaw doctor --fix to apply any remaining fixes
echo "[clawoop] Step 6: Running doctor --fix..."
node openclaw.mjs doctor --fix 2>&1 || true

# Step 7: Start the gateway
echo "[clawoop] Step 7: Starting gateway..."
exec node openclaw.mjs gateway --allow-unconfigured

#!/bin/sh
set -e

# Helper: update deploy_stage in Supabase (non-blocking, fail-silent)
update_stage() {
  if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_ROLE_KEY" ] && [ -n "$INSTANCE_ID" ]; then
    curl -sf -X PATCH "${SUPABASE_URL}/rest/v1/deployments?id=eq.${INSTANCE_ID}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Content-Type: application/json" \
      -d "{\"deploy_stage\": \"$1\"}" > /dev/null 2>&1 || true
  fi
}

echo "[clawoop] === Custom OpenClaw Entrypoint ==="
echo "[clawoop] Platform: ${PLATFORM:-telegram}"

# Step 1: Onboard the correct channel
update_stage "configuring"
echo "[clawoop] Step 1: Running openclaw onboard..."
# onboard is interactive (requires stdin) — skip in Docker
echo "[clawoop]   Skipping interactive onboard (Docker mode)"

# Step 2: Set channel config with dmPolicy=open via CLI
echo "[clawoop] Step 2: Setting channel config via CLI..."
if [ "$PLATFORM" = "slack" ]; then
  node openclaw.mjs config set --json channels.slack "{\"enabled\":true,\"dmPolicy\":\"open\",\"botToken\":\"$SLACK_BOT_TOKEN\",\"allowFrom\":[\"*\"]}" 2>&1 || true
elif [ "$PLATFORM" = "discord" ]; then
  node openclaw.mjs config set --json channels.discord "{\"enabled\":true,\"dmPolicy\":\"open\",\"botToken\":\"$DISCORD_BOT_TOKEN\",\"allowFrom\":[\"*\"]}" 2>&1 || true
elif [ "$PLATFORM" = "whatsapp" ]; then
  echo "[clawoop]   Setting up native WhatsApp channel via Baileys..."
  # Use OpenClaw's built-in WhatsApp support (Baileys)
  # dmPolicy=open allows anyone to message, allowFrom=["*"] accepts all senders
  node openclaw.mjs config set --json channels.whatsapp "{\"enabled\":true,\"dmPolicy\":\"open\",\"allowFrom\":[\"*\"]}" 2>&1 || true
else
  node openclaw.mjs config set --json channels.telegram "{\"enabled\":true,\"dmPolicy\":\"open\",\"botToken\":\"$TELEGRAM_BOT_TOKEN\",\"allowFrom\":[\"*\"]}" 2>&1 || true
fi

# Step 3: Set the AI model via valid OpenClaw config path
echo "[clawoop] Step 3: Setting AI model config..."
echo "[clawoop]   Model: ${AI_MODEL:-anthropic/claude-opus-4-6}"
# Use the correct OpenClaw config key: agents.defaults.model (provider/model format)
node openclaw.mjs config set --json agents.defaults.model "{\"primary\":\"${AI_MODEL:-anthropic/claude-opus-4-6}\"}" 2>&1 || true
echo "[clawoop]   Model set via agents.defaults.model ✓"
# API keys are read directly from env vars (ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.)
# No need for ai.credentials — OpenClaw detects keys from environment automatically.

# Step 3b: Ensure agent directory exists (auth handled via env vars)
echo "[clawoop] Step 3b: Ensuring agent directory exists..."
mkdir -p "/home/node/.openclaw/agents/main/agent"
echo "[clawoop]   Agent dir ready ✓ (API keys read from env vars: ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.)"

# Step 4: Configure Google OAuth for gog tool (Calendar, Gmail, Drive)
update_stage "connecting"
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

  # Configure gog CLI to use file-based keyring (works in containers)
  export GOG_KEYRING_BACKEND="${GOG_KEYRING_BACKEND:-file}"
  export GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD:-clawoop-default}"
  export GOG_ACCOUNT="${GOG_CONNECTED_EMAIL}"

  # Load credentials into gog CLI
  if command -v gog >/dev/null 2>&1; then
    # Set keyring backend to file (no system keychain in containers)
    gog auth keyring file 2>&1 || true
    # Store OAuth client credentials
    gog auth credentials /home/node/google-credentials.json 2>&1 || true
    # Import the refresh token directly (no browser needed)
    if [ -n "$GOG_CONNECTED_EMAIL" ]; then
      echo "$GOG_REFRESH_TOKEN" | gog auth tokens import "$GOG_CONNECTED_EMAIL" 2>&1 || true
    fi
    echo "[clawoop]   gog CLI configured with user's Google token"
  else
    echo "[clawoop]   gog not found — setting env vars for gog tool"
  fi

  # Enable Google tools in OpenClaw config
  # gog tool is auto-detected via GOG_REFRESH_TOKEN env var
  
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

# Step 4h: Configure Brave Search (web search for all agents)
if [ -n "$BRAVE_API_KEY" ]; then
  echo "[clawoop]   Brave Search API key found — enabling brave skill..."
  echo "BRAVE_API_KEY=$BRAVE_API_KEY" >> /home/node/.openclaw/.env
  echo "[clawoop]   Brave Search configured"
fi

# Step 4i: Configure Figma
if [ -n "$FIGMA_TOKEN" ]; then
  echo "[clawoop]   Figma token found — enabling figma skill..."
  echo "FIGMA_TOKEN=$FIGMA_TOKEN" >> /home/node/.openclaw/.env
  echo "[clawoop]   Figma configured"
fi

# Step 4j: Configure Linear
if [ -n "$LINEAR_API_KEY" ]; then
  echo "[clawoop]   Linear API key found — enabling linear skill..."
  echo "LINEAR_API_KEY=$LINEAR_API_KEY" >> /home/node/.openclaw/.env
  echo "[clawoop]   Linear configured"
fi

# Step 4k: Configure Todoist
if [ -n "$TODOIST_API_TOKEN" ]; then
  echo "[clawoop]   Todoist token found — enabling todoist skill..."
  echo "TODOIST_API_TOKEN=$TODOIST_API_TOKEN" >> /home/node/.openclaw/.env
  echo "[clawoop]   Todoist configured"
fi

# Step 4l: Configure Airtable
if [ -n "$AIRTABLE_PAT" ]; then
  echo "[clawoop]   Airtable PAT found — enabling airtable skill..."
  echo "AIRTABLE_PAT=$AIRTABLE_PAT" >> /home/node/.openclaw/.env
  echo "[clawoop]   Airtable configured"
fi

# Step 4m: Configure Jira
if [ -n "$JIRA_BASE_URL" ] && [ -n "$JIRA_EMAIL" ] && [ -n "$JIRA_API_TOKEN" ]; then
  echo "[clawoop]   Jira credentials found — enabling jira skill..."
  echo "JIRA_BASE_URL=$JIRA_BASE_URL" >> /home/node/.openclaw/.env
  echo "JIRA_EMAIL=$JIRA_EMAIL" >> /home/node/.openclaw/.env
  echo "JIRA_API_TOKEN=$JIRA_API_TOKEN" >> /home/node/.openclaw/.env
  echo "[clawoop]   Jira configured"
fi

# Step 4n: Configure HubSpot
if [ -n "$HUBSPOT_ACCESS_TOKEN" ]; then
  echo "[clawoop]   HubSpot token found — enabling hubspot skill..."
  echo "HUBSPOT_ACCESS_TOKEN=$HUBSPOT_ACCESS_TOKEN" >> /home/node/.openclaw/.env
  echo "[clawoop]   HubSpot configured"
fi

# Step 4o: Configure Reddit
if [ -n "$REDDIT_CLIENT_ID" ] && [ -n "$REDDIT_CLIENT_SECRET" ]; then
  echo "[clawoop]   Reddit credentials found — enabling reddit skill..."
  echo "REDDIT_CLIENT_ID=$REDDIT_CLIENT_ID" >> /home/node/.openclaw/.env
  echo "REDDIT_CLIENT_SECRET=$REDDIT_CLIENT_SECRET" >> /home/node/.openclaw/.env
  echo "[clawoop]   Reddit configured"
fi

# Step 5: Service tools are auto-detected via env vars
echo "[clawoop] Step 5: Service tools configured via env vars..."
# Tools (gog, notion, github, trello) are activated via their env vars,
# not via tools.* config keys. OpenClaw detects them automatically.
echo "[clawoop]   NOTION_API_KEY=${NOTION_API_KEY:+SET} GITHUB_TOKEN=${GITHUB_TOKEN:+SET} TRELLO_API_KEY=${TRELLO_API_KEY:+SET} BRAVE_API_KEY=${BRAVE_API_KEY:+SET}"
echo "[clawoop]   Tools ready ✓"

# Step 5b: Removed — openclaw doctor --fix is no longer needed
# (all invalid config keys have been cleaned up)

# Step 6: Write OpenClaw workspace files (IDENTITY.md, SOUL.md, TOOLS.md)
# OpenClaw builds its system prompt from these files — NOT from ai.systemPrompt
echo "[clawoop] Step 6: Writing workspace files..."

WORKSPACE="/home/node/.openclaw/workspace"
mkdir -p "$WORKSPACE"

# Debug: log which env vars are present
echo "[clawoop]   ENV CHECK: GOG_REFRESH_TOKEN=${GOG_REFRESH_TOKEN:+SET} NOTION_API_KEY=${NOTION_API_KEY:+SET} GITHUB_TOKEN=${GITHUB_TOKEN:+SET} BRAVE_API_KEY=${BRAVE_API_KEY:+SET}"

# 6a: IDENTITY.md — defines who the bot is
cat > "$WORKSPACE/IDENTITY.md" << 'EOF'
name: Clawoop Assistant
type: AI assistant
vibe: helpful, practical, proactive
emoji: 🤖
EOF
echo "[clawoop]   IDENTITY.md written ✓"

# 6b: Build connected/unconnected service lists for SOUL.md
CONNECTED_SERVICES=""
UNCONNECTED_SERVICES=""

if [ -n "$GOG_REFRESH_TOKEN" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Google Workspace**: Calendar (list/create/update events), Gmail (read/send emails), Drive (list/search files). Use the gog tool."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Google Workspace → https://clawoop.com?connect=google"
fi

if [ -n "$NOTION_API_KEY" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Notion**: Create pages, query databases, search workspace. Use the notion tool."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Notion → https://clawoop.com?connect=notion"
fi

if [ -n "$GITHUB_TOKEN" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **GitHub**: List repos, create/list issues, manage PRs. Use the github tool."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- GitHub → https://clawoop.com?connect=github"
fi

if [ -n "$SPOTIFY_CLIENT_ID" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Spotify**: Control playback, search music, manage playlists. Use curl with Spotify Web API."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Spotify → https://clawoop.com?connect=spotify"
fi

if [ -n "$TRELLO_API_KEY" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Trello**: List boards, create/move cards, manage lists. Use the trello tool."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Trello → https://clawoop.com?connect=trello"
fi

if [ -n "$X_API_KEY" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Twitter/X**: Post tweets, search, manage timeline. Use curl with X API v2."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Twitter/X → https://clawoop.com?connect=twitter"
fi

if [ -n "$HA_URL" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Home Assistant**: Control smart home devices. Use curl with HA REST API at ${HA_URL}."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Home Assistant → https://clawoop.com?connect=homeassistant"
fi

if [ -n "$BRAVE_API_KEY" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Brave Search**: Web search and browsing. Use the brave skill (curl to api.search.brave.com)."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Brave Search → set BRAVE_API_KEY in backend to enable"
fi

if [ -n "$FIGMA_TOKEN" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Figma**: Inspect design files, export assets, list components and styles. Use curl with the Figma REST API."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Figma → https://clawoop.com?connect=figma"
fi

if [ -n "$LINEAR_API_KEY" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Linear**: List and manage issues, projects, and team workflows. Use curl with the Linear GraphQL API."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Linear → https://clawoop.com?connect=linear"
fi

if [ -n "$TODOIST_API_TOKEN" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Todoist**: Manage tasks, projects, and reminders. Use curl with the Todoist REST API."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Todoist → https://clawoop.com?connect=todoist"
fi

if [ -n "$AIRTABLE_PAT" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Airtable**: Read, create, update, and delete records in bases and tables. Use curl with the Airtable REST API."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Airtable → https://clawoop.com?connect=airtable"
fi

if [ -n "$JIRA_BASE_URL" ] && [ -n "$JIRA_API_TOKEN" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Jira**: Search, create, and update issues; manage project workflows. Use curl with the Jira REST API at ${JIRA_BASE_URL}."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Jira → https://clawoop.com?connect=jira"
fi

if [ -n "$HUBSPOT_ACCESS_TOKEN" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **HubSpot**: Manage CRM contacts, companies, and deals. Use curl with the HubSpot API."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- HubSpot → https://clawoop.com?connect=hubspot"
fi

if [ -n "$REDDIT_CLIENT_ID" ]; then
  CONNECTED_SERVICES="${CONNECTED_SERVICES}
- **Reddit**: Browse and search subreddits, posts, and comments (read-only). Use curl with the Reddit API."
else
  UNCONNECTED_SERVICES="${UNCONNECTED_SERVICES}
- Reddit → https://clawoop.com?connect=reddit"
fi

# 6c: SOUL.md — core personality, rules, and integration awareness
cat > "$WORKSPACE/SOUL.md" << SOUL_EOF
# Soul

You are a helpful AI assistant managed by Clawoop. You can chat naturally and also perform real actions through connected services.

## Connected Services (ready to use)
${CONNECTED_SERVICES:-No services connected yet.}

## Services Not Yet Connected
If the user asks for something that needs one of these, tell them which service is needed and share the connection link:
${UNCONNECTED_SERVICES:-All services are connected!}

## Core Rules
- For connected services, take action directly when asked. Don't ask for confirmation unless the action is destructive.
- For unconnected services, explain what's needed and share the exact connection link.
- Never fabricate data. If a tool call fails, tell the user honestly.
- Be concise and helpful.
- Always respond in English by default. If the user writes in another language, match their language.
- Skip onboarding questions — you are already fully configured and ready to help.
- If an AI request fails with a credit_exceeded or rate_limit error, tell the user: "Your monthly AI credits have been used up. They will be renewed in the next billing cycle." Do not retry.
SOUL_EOF
echo "[clawoop]   SOUL.md written ✓"

# 6d: USER.md — basic user context
cat > "$WORKSPACE/USER.md" << 'EOF'
# User

The user is a Clawoop subscriber who has deployed this AI assistant. Help them with any task — from scheduling meetings to managing files. Be proactive and practical. Always default to English. If the user writes in another language, respond in that language instead.
EOF
echo "[clawoop]   USER.md written ✓"

# 6e: Remove BOOTSTRAP.md — prevents onboarding questions
echo "[clawoop] Step 6e: Removing BOOTSTRAP.md..."
rm -f "$WORKSPACE/BOOTSTRAP.md" 2>/dev/null || true
rm -f /home/node/.openclaw/BOOTSTRAP.md 2>/dev/null || true
rm -f /home/node/BOOTSTRAP.md 2>/dev/null || true
find /home/node -name "BOOTSTRAP.md" -delete 2>/dev/null || true
echo "[clawoop]   BOOTSTRAP.md removed ✓"

# 6f: Verify workspace files
echo "[clawoop]   Workspace files:"
ls -la "$WORKSPACE/" 2>/dev/null || echo "   (workspace dir not found)"
echo "[clawoop]   SOUL.md preview:"
cat "$WORKSPACE/SOUL.md" 2>/dev/null | head -5 || echo "   (SOUL.md not found)"

# Step 7b: Deploy service skills
echo "[clawoop] Step 7b: Deploying service skills..."
SKILLS_SRC="/home/node/skills"
SKILLS_DST="/home/node/.openclaw/skills"
if [ -d "$SKILLS_SRC" ]; then
  mkdir -p "$SKILLS_DST"
  cp -r "$SKILLS_SRC"/* "$SKILLS_DST/" 2>/dev/null || true
  SKILL_COUNT=$(ls -d "$SKILLS_DST"/*/ 2>/dev/null | wc -l)
  echo "[clawoop]   Deployed $SKILL_COUNT skill(s) to $SKILLS_DST"
  ls -d "$SKILLS_DST"/*/ 2>/dev/null | xargs -I{} basename {} | while read s; do echo "[clawoop]     - $s"; done
else
  echo "[clawoop]   No skills directory found at $SKILLS_SRC — skipping"
fi

# Step 8: Start credit proxy (if Supabase creds available)
echo "[clawoop] Step 8: Starting credit proxy..."
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_ROLE_KEY" ] && [ -n "$USER_ID" ]; then
  node /home/node/credit-proxy.mjs &
  PROXY_PID=$!
  sleep 1
  echo "[clawoop]   Credit proxy started (PID: $PROXY_PID)"

  # Override AI provider base URL to route through proxy
  export ANTHROPIC_BASE_URL="http://127.0.0.1:4100"
  export OPENAI_BASE_URL="http://127.0.0.1:4100"
  export XAI_BASE_URL="http://127.0.0.1:4100"
  export DEEPSEEK_BASE_URL="http://127.0.0.1:4100"
  echo "[clawoop]   AI requests routed through credit proxy"
else
  echo "[clawoop]   Supabase creds missing — credit proxy skipped (no cap enforced)"
fi

# Step 9: Start credential poller (hot-reload integrations without restart)
echo "[clawoop] Step 9: Starting credential poller..."
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_ROLE_KEY" ] && [ -n "$USER_ID" ]; then
  node /home/node/credential-poller.mjs &
  POLLER_PID=$!
  echo "[clawoop]   Credential poller started (PID: $POLLER_PID)"
else
  echo "[clawoop]   Missing Supabase creds — credential poller skipped"
fi

# Step 10: Start the gateway (with auto-restart on crash)
update_stage "starting"
echo "[clawoop] Step 10: Starting gateway..."

# Clean up any stale openclaw.json from previous deploys
rm -f /home/node/.openclaw/openclaw.json 2>/dev/null

MAX_RETRIES=5
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
  RETRY=$((RETRY + 1))
  echo "[clawoop]   Gateway start attempt $RETRY/$MAX_RETRIES"

  if [ "$PLATFORM" = "whatsapp" ]; then
    node openclaw.mjs gateway --allow-unconfigured 2>&1 | node /home/node/qr-watcher.mjs &
  else
    node openclaw.mjs gateway --allow-unconfigured 2>&1 &
  fi
  GATEWAY_PID=$!

  # Health check — wait for gateway process to stabilize, then mark as running
  if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_ROLE_KEY" ] && [ -n "$INSTANCE_ID" ]; then
    (
      # Give gateway 8s to start and stabilize
      sleep 8
      if kill -0 $GATEWAY_PID 2>/dev/null; then
        echo "[clawoop]   Gateway process alive after 8s — marking as running"
        curl -sf -X PATCH "${SUPABASE_URL}/rest/v1/deployments?id=eq.${INSTANCE_ID}" \
          -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
          -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
          -H "Content-Type: application/json" \
          -d '{"status": "running", "deploy_stage": "ready"}' > /dev/null 2>&1
        echo "[clawoop]   Status updated to running ✓"
      else
        echo "[clawoop]   Gateway process died within 20s"
      fi
    ) &
  fi

  # Wait for gateway to exit (|| true prevents set -e from killing the script)
  wait $GATEWAY_PID || true
  EXIT_CODE=$?
  echo "[clawoop]   Gateway exited with code $EXIT_CODE"

  if [ $RETRY -lt $MAX_RETRIES ]; then
    DELAY=$((RETRY * 5))
    echo "[clawoop]   Restarting in ${DELAY}s..."
    sleep $DELAY

    # After first crash, Doctor has auto-configured defaults.
    # Re-apply our dmPolicy=open so everyone can message the bot.
    if [ $RETRY -eq 1 ]; then
      echo "[clawoop]   Re-applying channel config after Doctor..."
      if [ "$PLATFORM" = "slack" ]; then
        node openclaw.mjs config set --json channels.slack "{\"enabled\":true,\"dmPolicy\":\"open\",\"botToken\":\"$SLACK_BOT_TOKEN\",\"allowFrom\":[\"*\"]}" 2>&1 || true
      elif [ "$PLATFORM" = "discord" ]; then
        node openclaw.mjs config set --json channels.discord "{\"enabled\":true,\"dmPolicy\":\"open\",\"botToken\":\"$DISCORD_BOT_TOKEN\",\"allowFrom\":[\"*\"]}" 2>&1 || true
      elif [ "$PLATFORM" = "whatsapp" ]; then
        node openclaw.mjs config set --json channels.whatsapp "{\"enabled\":true,\"dmPolicy\":\"open\",\"allowFrom\":[\"*\"]}" 2>&1 || true
      else
        node openclaw.mjs config set --json channels.telegram "{\"enabled\":true,\"dmPolicy\":\"open\",\"botToken\":\"$TELEGRAM_BOT_TOKEN\",\"allowFrom\":[\"*\"]}" 2>&1 || true
      fi
    fi
  fi
done

echo "[clawoop]   Gateway failed after $MAX_RETRIES attempts"
# Update status to error
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_ROLE_KEY" ] && [ -n "$INSTANCE_ID" ]; then
  curl -sf -X PATCH "${SUPABASE_URL}/rest/v1/deployments?id=eq.${INSTANCE_ID}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"status": "error", "deploy_stage": "building"}' > /dev/null 2>&1
fi


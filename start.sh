#!/bin/bash
# =============================================================
#  🚀 Hermes Agent Stack — Railway Start
# =============================================================
echo "══════════════════════════════════════════"
echo "  🚀 Hermes Agent Stack — Railway Start"
echo "══════════════════════════════════════════"
echo "PORT=${PORT:-3000}"
echo "Starting at: $(date)"

export NGINX_PORT="${PORT:-3000}"

# ── 9Router connection (external service) ────────────────
R9_URL="${R9_URL:-https://9router-production-eac7.up.railway.app/v1}"
R9_API_KEY="${R9_API_KEY:-}"

# Set env vars for hermes agent compatibility
export CUSTOM_API_KEY="$R9_API_KEY"
export CUSTOM_BASE_URL="$R9_URL"

echo "[1] Writing Hermes config..."
mkdir -p /data/.hermes

# Remove old config so we start fresh
rm -f /data/.hermes/config.yaml

if [ -n "$R9_API_KEY" ]; then
  cat > /data/.hermes/config.yaml << CONFIG
model:
  default: Flash
  provider: custom:9router
  base_url: ${R9_URL}
  api_key: ${R9_API_KEY}
  api_mode: chat_completions

custom_providers:
  - name: 9router
    base_url: ${R9_URL}
    api_key: ${R9_API_KEY}
    api_mode: chat_completions

display:
  tool_progress: all

agent:
  max_turns: 150

platforms:
  telegram:
    enabled: false
CONFIG
  echo "  ✅ Config written (R9_URL=${R9_URL})"
else
  echo "  ⚠️  R9_API_KEY not set — keeping existing config.yaml (if any)"
fi

echo "[2] Rendering Nginx config..."
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
nginx -t
if [ $? -ne 0 ]; then
    echo "❌ Nginx config test FAILED!"
    exit 1
fi

echo "[3] Starting Hermes WebUI (port 8787)..."
cd /app/hermes-webui
export HERMES_WEBUI_PORT=8787
export HERMES_WEBUI_HOST=127.0.0.1
export HERMES_HOME="/data"
nohup python3 server.py > /tmp/hermes-webui.log 2>&1 &
WEBUI_PID=$!
echo "  → PID: $WEBUI_PID"

sleep 3
if kill -0 $WEBUI_PID 2>/dev/null; then
    echo "  ✅ WebUI is running"
else
    echo "  ⚠️ WebUI failed to start!"
    tail -20 /tmp/hermes-webui.log
fi

echo "[4] Starting Nginx on port ${NGINX_PORT}..."
nginx -g "daemon off;"

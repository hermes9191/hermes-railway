#!/bin/bash
# =============================================================
#  Hermes WebUI — Railway entrypoint
#  Architecture: this service = Agent + WebUI + nginx
#                9Router      = separate Railway service
#  NO set -e — a background crash must not kill nginx
# =============================================================
echo "══════════════════════════════════════════"
echo "  Hermes WebUI — Railway Start"
echo "══════════════════════════════════════════"
echo "PORT=${PORT:-3000}"
echo "Starting at: $(date)"

export NGINX_PORT="${PORT:-3000}"

# HERMES_HOME CONTAINS config.yaml and .env (not a parent of .hermes/)
export HERMES_HOME="${HERMES_HOME:-/data}"
export HERMES_DATA_DIR="${HERMES_DATA_DIR:-/data}"

# External 9Router (public URL + API key from Railway Variables)
R9_URL="${R9_URL:-https://9router-production-eac7.up.railway.app/v1}"
R9_API_KEY="${R9_API_KEY:-}"

# Belt-and-suspenders for hermes_cli runtime_provider candidates
export CUSTOM_API_KEY="$R9_API_KEY"
export CUSTOM_BASE_URL="$R9_URL"
export OPENAI_API_KEY="$R9_API_KEY"
export OPENROUTER_API_KEY="$R9_API_KEY"

echo "[1] Writing Hermes config under HERMES_HOME=${HERMES_HOME}..."
mkdir -p "${HERMES_HOME}"

# Wipe stale wrong layout from older deploys
rm -f "${HERMES_HOME}/.hermes/config.yaml" 2>/dev/null || true
rm -f /data/.hermes/config.yaml 2>/dev/null || true

if [ -n "$R9_API_KEY" ]; then
  cat > "${HERMES_HOME}/config.yaml" << CONFIG
model:
  default: Flash
  provider: custom
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

  cat > "${HERMES_HOME}/.env" << ENVFILE
CUSTOM_API_KEY=${R9_API_KEY}
CUSTOM_BASE_URL=${R9_URL}
OPENAI_API_KEY=${R9_API_KEY}
OPENROUTER_API_KEY=${R9_API_KEY}
ENVFILE

  echo "  OK config: ${HERMES_HOME}/config.yaml (api_key length: ${#R9_API_KEY})"
  echo "  OK env:    ${HERMES_HOME}/.env"
  echo "  OK R9_URL=${R9_URL}"
else
  echo "  WARN R9_API_KEY not set — chat will 401 against 9Router"
  echo "  Set R9_API_KEY on this service in Railway Variables, then Redeploy."
fi

echo "[2] Rendering Nginx..."
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
if ! nginx -t; then
  echo "FAIL nginx config test"
  exit 1
fi

echo "[3] Starting Hermes WebUI on 127.0.0.1:8787..."
cd /app/hermes-webui
export HERMES_WEBUI_PORT=8787
export HERMES_WEBUI_HOST=127.0.0.1
export HERMES_HOME="${HERMES_HOME}"
nohup python3 server.py > /tmp/hermes-webui.log 2>&1 &
WEBUI_PID=$!
echo "  PID: $WEBUI_PID"

sleep 3
if kill -0 "$WEBUI_PID" 2>/dev/null; then
  echo "  OK WebUI running"
else
  echo "  WARN WebUI failed to start — last log lines:"
  tail -40 /tmp/hermes-webui.log || true
fi

echo "[4] Nginx foreground on port ${NGINX_PORT}..."
exec nginx -g "daemon off;"

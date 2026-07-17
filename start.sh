#!/bin/bash
# =============================================================
#  🚀 Hermes Agent Stack — Railway Start
# =============================================================
# NO set -e — background service crash must not kill nginx
echo "══════════════════════════════════════════"
echo "  🚀 Hermes Agent Stack — Railway Start"
echo "══════════════════════════════════════════"
echo "PORT=${PORT:-3000}"
echo "Starting at: $(date)"

export NGINX_PORT="${PORT:-3000}"

# HERMES_HOME is the directory that CONTAINS config.yaml and .env
# (NOT a parent of .hermes — get_config_path() = HERMES_HOME/config.yaml)
export HERMES_HOME="${HERMES_HOME:-/data}"
export HERMES_DATA_DIR="${HERMES_DATA_DIR:-/data}"

# ── 9Router connection (external service) ────────────────
R9_URL="${R9_URL:-https://9router-production-eac7.up.railway.app/v1}"
R9_API_KEY="${R9_API_KEY:-}"

# Belt-and-suspenders env exports (host-gated for some paths; config.yaml is the real source)
export CUSTOM_API_KEY="$R9_API_KEY"
export CUSTOM_BASE_URL="$R9_URL"
export OPENAI_API_KEY="$R9_API_KEY"
export OPENROUTER_API_KEY="$R9_API_KEY"

echo "[1] Writing Hermes config under HERMES_HOME=${HERMES_HOME}..."
mkdir -p "${HERMES_HOME}"

# Remove stale paths from older deploys (wrong layout: /data/.hermes/config.yaml)
# Hermes reads: ${HERMES_HOME}/config.yaml  →  /data/config.yaml when HERMES_HOME=/data
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

  # Also write .env under HERMES_HOME (hermes_cli loads secrets from here)
  cat > "${HERMES_HOME}/.env" << ENVFILE
CUSTOM_API_KEY=${R9_API_KEY}
CUSTOM_BASE_URL=${R9_URL}
OPENAI_API_KEY=${R9_API_KEY}
OPENROUTER_API_KEY=${R9_API_KEY}
ENVFILE

  echo "  ✅ Config: ${HERMES_HOME}/config.yaml (api_key length: ${#R9_API_KEY})"
  echo "  ✅ Env file: ${HERMES_HOME}/.env"
  echo "  ✅ R9_URL=${R9_URL}"
  # Prove path matches what hermes_constants expects
  if [ -f "${HERMES_HOME}/config.yaml" ]; then
    echo "  ✅ Verified config exists at expected path"
  else
    echo "  ❌ Config missing after write!"
  fi
else
  echo "  ⚠️  R9_API_KEY not set — config.yaml won't have API key!"
  echo "  Set R9_API_KEY in Railway Variables for this service, then Redeploy."
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
# Critical: WebUI + agent must see same HERMES_HOME so resolve_runtime_provider
# loads model.api_key from the file we just wrote.
export HERMES_HOME="${HERMES_HOME}"
nohup python3 server.py > /tmp/hermes-webui.log 2>&1 &
WEBUI_PID=$!
echo "  → PID: $WEBUI_PID"

sleep 3
if kill -0 $WEBUI_PID 2>/dev/null; then
    echo "  ✅ WebUI is running"
else
    echo "  ⚠️ WebUI failed to start!"
    tail -40 /tmp/hermes-webui.log || true
fi

echo "[4] Starting Nginx on port ${NGINX_PORT}..."
nginx -g "daemon off;"

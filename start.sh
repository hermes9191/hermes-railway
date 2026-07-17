#!/bin/bash
# =============================================================
#  🚀 Hermes Agent Stack — Railway Start
# =============================================================
echo "══════════════════════════════════════════"
echo "  🚀 Hermes Agent Stack — Railway Start"
echo "══════════════════════════════════════════"
echo "PORT=${PORT:-3000}"

export NGINX_PORT="${PORT:-3000}"

# 9Router defaults
export DATA_DIR="${DATA_DIR:-/app/data}"
export NODE_ENV="${NODE_ENV:-production}"
export JWT_SECRET="${JWT_SECRET:-}"
export INITIAL_PASSWORD="${INITIAL_PASSWORD:-}"
export API_KEY_SECRET="${API_KEY_SECRET:-}"
export MACHINE_ID_SALT="${MACHINE_ID_SALT:-}"
export BASE_URL="${BASE_URL:-http://localhost:${NGINX_PORT}}"
export NEXT_PUBLIC_BASE_URL="${NEXT_PUBLIC_BASE_URL:-http://localhost:${NGINX_PORT}}"

echo "[1] Rendering Nginx config..."
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "[2] Starting background services..."

# Start Hermes WebUI (port 8787)
cd /app/hermes-webui
export HERMES_WEBUI_PORT=8787
export HERMES_WEBUI_HOST=127.0.0.1
export HERMES_HOME="/data"
nohup python3 server.py > /tmp/hermes-webui.log 2>&1 &
echo "  → WebUI PID: $!"

# Start 9Router AI Gateway (port 20128)
cd /app/9router
export PORT=20128
export HOSTNAME=0.0.0.0
cp custom-server.js .next/standalone/custom-server.js 2>/dev/null
cd .next/standalone
nohup node custom-server.js > /tmp/9router.log 2>&1 &
echo "  → 9Router PID: $!"

echo "[3] Starting Nginx on port ${NGINX_PORT}..."
nginx -t && nginx -g "daemon off;"

echo ""
echo "══════════════════════════════════════════"
echo "  ✅ Services started!"
echo "══════════════════════════════════════════"

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

# 9Router defaults
export DATA_DIR="${DATA_DIR:-/app/data}"
export JWT_SECRET="${JWT_SECRET:-}"
export INITIAL_PASSWORD="${INITIAL_PASSWORD:-}"
export API_KEY_SECRET="${API_KEY_SECRET:-}"
export MACHINE_ID_SALT="${MACHINE_ID_SALT:-}"
export BASE_URL="${BASE_URL:-http://localhost:${NGINX_PORT}}"
export NEXT_PUBLIC_BASE_URL="${NEXT_PUBLIC_BASE_URL:-http://localhost:${NGINX_PORT}}"

echo "[1] Rendering Nginx config..."
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
cat /etc/nginx/nginx.conf

echo "[2] Testing config..."
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

sleep 2
if kill -0 $WEBUI_PID 2>/dev/null; then
    echo "  ✅ WebUI is running"
else
    echo "  ⚠️ WebUI failed to start!"
    cat /tmp/hermes-webui.log
fi

echo "[4] Starting 9Router AI Gateway (port 20128)..."
cd /app/9router
cp custom-server.js .next/standalone/custom-server.js 2>/dev/null
cd .next/standalone
if [ -f server.js ]; then
    echo "  ✅ server.js found in standalone"
else
    echo "  ❌ server.js not found!"
    ls -la
fi
export PORT=20128
export HOSTNAME=0.0.0.0
nohup node custom-server.js > /tmp/9router.log 2>&1 &
R9_PID=$!
echo "  → PID: $R9_PID"

sleep 3
if kill -0 $R9_PID 2>/dev/null; then
    echo "  ✅ 9Router is running"
else
    echo "  ⚠️ 9Router failed to start!"
    cat /tmp/9router.log
fi

echo "[5] Starting Nginx on port ${NGINX_PORT}..."
nginx -g "daemon off;"

echo ""
echo "══════════════════════════════════════════"
echo "  ✅ Services started!"
echo "═══╦══════════════════════════════════════"
echo "  ║ WebUI  → http://127.0.0.1:8787"
echo "  ║ 9Router→ http://127.0.0.1:20128"
echo "  ║ Nginx  → http://0.0.0.0:${NGINX_PORT}"
echo "══════════════════════════════════════════"

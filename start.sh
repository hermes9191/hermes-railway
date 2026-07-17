#!/bin/bash
set -e

echo "══════════════════════════════════════════"
echo "  🚀 Hermes Agent Stack — Railway Start"
echo "══════════════════════════════════════════"
echo "PORT=${PORT:-3000}"

# ── 1. Set defaults (قابل override با Railway env vars) ──────────────
export NGINX_PORT="${PORT:-3000}"

# 9Router defaults (در صورت ست نشدن توی Railway)
export DATA_DIR="${DATA_DIR:-/app/data}"
export NODE_ENV="${NODE_ENV:-production}"
export JWT_SECRET="${JWT_SECRET:-}"
export INITIAL_PASSWORD="${INITIAL_PASSWORD:-}"
export API_KEY_SECRET="${API_KEY_SECRET:-}"
export MACHINE_ID_SALT="${MACHINE_ID_SALT:-}"
export BASE_URL="${BASE_URL:-http://localhost:${NGINX_PORT}}"
export NEXT_PUBLIC_BASE_URL="${NEXT_PUBLIC_BASE_URL:-http://localhost:${NGINX_PORT}}"
export DISABLE_TELEMETRY="${DISABLE_TELEMETRY:-1}"

# ── 2. Render Nginx Config ───────────────────────────────────────────
echo "[1] Rendering Nginx config..."
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# ── 3. Start Nginx ───────────────────────────────────────────────────
echo "[2] Starting Nginx on port ${NGINX_PORT}..."
nginx -t
nginx -g "daemon on;"

# ── 4. Start Hermes WebUI (port 8787) — Main UI ─────────────────────
echo "[3] Starting Hermes WebUI..."
cd /app/hermes-webui
export HERMES_WEBUI_PORT=8787
export HERMES_WEBUI_HOST=127.0.0.1
export HERMES_HOME="/data"
python3 server.py 2>&1 &
echo "  → PID: $!"

# ── 5. Start 9Router AI Gateway (port 20128) ─────────────────────────
echo "[4] Starting 9Router AI Gateway..."
cd /app/9router
export PORT=20128
export HOSTNAME=0.0.0.0
node custom-server.js 2>&1 &
echo "  → PID: $!"

echo ""
echo "══════════════════════════════════════════"
echo "  ✅ همه سرویس‌ها در حال اجرا هستند!"
echo "══════════════════════════════════════════"
echo ""
echo "  🌐 Hermes WebUI     : /           → 127.0.0.1:8787"
echo "  🔀 9Router API     : /v1         → 127.0.0.1:20128"
echo "  🔀 9Router Panel   : /9router    → 127.0.0.1:20128"
echo ""

# زنده نگه داشتن کانتینر و نمایش لاگ‌ها
tail -f /var/log/nginx/access.log /var/log/nginx/error.log 2>/dev/null || \
  tail -f /dev/null

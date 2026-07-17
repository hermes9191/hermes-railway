FROM python:3.11-slim

# Runtime deps only — 9Router is a separate Railway service (own subdomain).
# No Node.js: this image serves Hermes Agent + Hermes WebUI behind nginx.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    nginx \
    ffmpeg \
    gettext-base \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1) Hermes Agent (WebUI imports hermes_cli / runtime from this install)
RUN git clone --depth 1 https://github.com/NousResearch/hermes-agent.git /app/hermes-agent \
    && cd /app/hermes-agent \
    && pip install --no-cache-dir -e .

# 2) Hermes WebUI (auto-discovers agent via Python imports)
RUN git clone --depth 1 https://github.com/nesquena/hermes-webui.git /app/hermes-webui \
    && cd /app/hermes-webui \
    && pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /data /var/log

# HERMES_HOME is the directory that CONTAINS config.yaml and .env
# get_config_path() = HERMES_HOME/config.yaml  →  /data/config.yaml
ENV HERMES_DATA_DIR=/data \
    HERMES_HOME=/data \
    PYTHONUNBUFFERED=1

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Railway injects $PORT; start.sh binds nginx to it
CMD ["/start.sh"]

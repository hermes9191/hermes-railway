FROM python:3.11-slim

# ۱. نصب پیش‌نیازهای لینوکس، Nginx، Node.js و Build Tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    nginx \
    ffmpeg \
    gettext-base \
    build-essential \
    python3 \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ════════════════════════════════════════
# ۳. Hermes Agent (لازمه چون webui بهش وصل میشه)
# ════════════════════════════════════════
RUN git clone https://github.com/NousResearch/hermes-agent.git /app/hermes-agent
RUN cd /app/hermes-agent && pip install -e .

# ════════════════════════════════════════
# ۴. Hermes WebUI (nesquena) — رابط کاربری اصلی
# ════════════════════════════════════════
RUN git clone https://github.com/nesquena/hermes-webui.git /app/hermes-webui
RUN cd /app/hermes-webui && pip install -r requirements.txt

# ════════════════════════════════════════
# ۵. 9Router (decolua) — AI Gateway
# ════════════════════════════════════════
RUN git clone https://github.com/decolua/9router.git /app/9router
RUN cd /app/9router && npm install && npm run build

# ════════════════════════════════════════
# ۶. تنظیمات نهایی
# ════════════════════════════════════════
RUN mkdir -p /data /var/log
ENV HERMES_DATA_DIR="/data"
ENV HERMES_HOME="/data"

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Railway پورت رو از طریق $PORT تزریق می‌کنه
CMD ["/start.sh"]

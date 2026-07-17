FROM python:3.11-slim

# ۱. نصب پیش‌نیازهای لینوکس، Nginx و Node.js
RUN apt-get update && apt-get install -y \
    curl \
    git \
    nginx \
    ffmpeg \
    gettext-base \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ۲. نصب uv برای پایتون
ENV UV_SYSTEM_PYTHON=1
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# ════════════════════════════════════════
# ۳. Hermes Agent (لازمه چون webui بهش وصل میشه)
# ════════════════════════════════════════
RUN git clone https://github.com/NousResearch/hermes-agent.git /app/hermes-agent
RUN cd /app/hermes-agent && uv pip install -e .

# ════════════════════════════════════════
# ۴. Hermes WebUI (nesquena) — رابط کاربری اصلی
# ════════════════════════════════════════
RUN git clone https://github.com/nesquena/hermes-webui.git /app/hermes-webui
RUN cd /app/hermes-webui && pip install -r requirements.txt

# ════════════════════════════════════════
# ۵. 9Router (decolua) — AI Gateway
# ════════════════════════════════════════
RUN git clone https://github.com/decolua/9router.git /app/9router
RUN cd /app/9router && npm ci && npm run build

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

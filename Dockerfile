FROM node:20-slim

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Clone 9Router from original repo
RUN git clone https://github.com/decolua/9router.git /app/9router

WORKDIR /app/9router

RUN mkdir -p /app/data && \
    cp .env.example .env 2>/dev/null || true

RUN npm install && npm run build

# Fix standalone mode: Next.js standalone expects static files at
# .next/standalone/.next/static/ but build puts them at .next/static/
# Symlink to make them accessible
RUN mkdir -p /app/9router/.next/standalone/.next && \
    ln -sf /app/9router/.next/static /app/9router/.next/standalone/.next/static

# Also need public/ folder
RUN cp -r public /app/9router/.next/standalone/public 2>/dev/null || true

RUN rm -rf .env

EXPOSE ${PORT:-8080}

ENV DATA_DIR=/app/data
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0

CMD cp custom-server.js .next/standalone/custom-server.js && \
    cp -r public .next/standalone/public 2>/dev/null; \
    cd .next/standalone && \
    node custom-server.js

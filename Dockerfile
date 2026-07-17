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

RUN rm -rf .env

EXPOSE 8080

ENV DATA_DIR=/app/data
ENV NODE_ENV=production
ENV PORT=8080
ENV HOSTNAME=0.0.0.0

CMD cp custom-server.js .next/standalone/custom-server.js && cd .next/standalone && node custom-server.js

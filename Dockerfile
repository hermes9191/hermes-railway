FROM node:20-slim

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/9router

COPY . .

RUN npm install && npm run build

RUN mkdir -p /app/data

EXPOSE 8080

ENV DATA_DIR=/app/data
ENV NODE_ENV=production
ENV PORT=8080
ENV HOSTNAME=0.0.0.0

CMD cp custom-server.js .next/standalone/custom-server.js && cd .next/standalone && node custom-server.js

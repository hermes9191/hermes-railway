FROM node:20-slim

WORKDIR /app

RUN apt-get update && apt-get install -y git build-essential && rm -rf /var/lib/apt/lists/*

# Clone and build 9Router
RUN git clone https://github.com/decolua/9router.git /app/9router
WORKDIR /app/9router
RUN npm install && npm run build

# Create data dir
RUN mkdir -p /app/data

EXPOSE 8080

ENV DATA_DIR=/app/data
ENV NODE_ENV=production
ENV PORT=8080
ENV HOSTNAME=0.0.0.0

CMD cp custom-server.js .next/standalone/custom-server.js && cd .next/standalone && node custom-server.js

FROM node:20-alpine

# Add non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /opt/mywebapp

COPY package*.json ./
RUN npm ci --only=production

COPY app.js routes.js db.js migrate.js ./

ENV NODE_ENV=production

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8000/health/alive || exit 1

CMD ["sh", "-c", "node migrate.js && node app.js"]
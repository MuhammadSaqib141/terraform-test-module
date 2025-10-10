FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code
COPY . .

# Security: Create a dedicated user and group to run the app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the port the app listens on
EXPOSE 3000

# Add a health check that Container Apps will use
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget -q --spider http://localhost:3000/healthz || exit 1

# Define the command to start the app
CMD [ "node", "index.js" ]
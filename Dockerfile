# syntax=docker/dockerfile:1

# ============================================
# Build stage - use Bun to honor bun.lock exactly
# ============================================
FROM oven/bun:1 AS builder

WORKDIR /app

# Install all deps (dev + prod) using the bun lockfile
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

# Copy the rest of the source
COPY . .

# Production build (TanStack Start + Cloudflare Vite plugin -> dist/)
RUN bun run build

# ============================================
# Runtime stage - lightweight Node
# ============================================
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copy build artifacts (Cloudflare Vite plugin outputs to dist/)
COPY --from=builder /app/dist ./dist

# Copy the Node.js server wrapper
COPY --from=builder /app/railway-server.mjs ./railway-server.mjs

# Copy package.json and node_modules for runtime dependency resolution
# (Vite externalizes some packages like h3-v2 that must be available at runtime)
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3000

CMD ["sh", "-c", "PORT=${PORT:-3000} node railway-server.mjs"]

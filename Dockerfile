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

# Production build (TanStack Start / Vinxi -> .output)
RUN bun run build

# ============================================
# Runtime stage - lightweight Node
# ============================================
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copy only the build artifacts we need
COPY --from=builder /app/.output ./.output

# package.json not strictly required at runtime for this setup, but harmless
COPY --from=builder /app/package.json ./

EXPOSE 3000

# Shell form ensures Railway's PORT env is visible to the process.
# We explicitly set PORT for the node process (Vinxi/Nitro reads process.env.PORT,
# falling back to 3000). This matches Railway + TanStack Start recommendations.
CMD ["sh", "-c", "PORT=${PORT:-3000} node .output/server/index.mjs"]

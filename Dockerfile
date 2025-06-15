###############  Stage 1 : builder  ###############
FROM node:22-alpine AS builder

# Dùng corepack (có sẵn trong Node 22) để kích hoạt pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Cài dependency (dev + prod) để build
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile --ignore-scripts

# Copy source & build
COPY . .
RUN pnpm run build

# Giữ lại **chỉ** dependency production
RUN pnpm prune --prod

###############  Stage 2 : runtime  ###############
FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

# Copy code, node_modules, metadata từ builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-lock.yaml* ./

# Ghi chú cổng mặc định (Railway vẫn tự cấp PORT)
EXPOSE 8080

CMD ["node", "dist/index.js"]

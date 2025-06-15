# ─────────────── Stage 1: Build ───────────────
FROM node:22-alpine AS builder

RUN npm install -g pnpm
WORKDIR /app

# Cài deps theo lockfile
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile --ignore-scripts

# Copy nguồn & build
COPY . .
RUN pnpm run build

# ─────────────── Stage 2: Runtime ─────────────
FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

# Lấy file build & metadata
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-lock.yaml* ./

# Chỉ cài phụ thuộc production
RUN npm install -g pnpm \
 && pnpm install --prod --frozen-lockfile --ignore-scripts \
 && pnpm cache clean --force

# (Tùy chọn) Ghi chú cổng mặc định ứng dụng
EXPOSE 8080
# Railway sẽ tự bơm biến PORT và bạn *phải*
# listen(process.env.PORT) trong code.

# Chạy server
CMD ["node", "dist/index.js"]

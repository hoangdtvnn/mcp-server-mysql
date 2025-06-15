# ───────────────────────────── stage 1: build ─────────────────────────────
FROM node:22-alpine AS builder

# Cài pnpm (nhanh & ít rác hơn npm)
RUN npm install -g pnpm

WORKDIR /app

# Cài deps dựa trên lockfile
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile --ignore-scripts

# Copy toàn bộ mã nguồn & build
COPY . .
RUN pnpm run build

# ───────────────────────────── stage 2: runtime ────────────────────────────
FROM node:22-alpine

# Thiết lập production mode
ENV NODE_ENV=production

WORKDIR /app

# Lấy file build & metadata từ stage builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-lock.yaml* ./

# Cài **chỉ** các phụ thuộc production
RUN npm install -g pnpm \
  && pnpm install --prod --frozen-lockfile --ignore-scripts \
  && pnpm cache clean --force

# Railway sẽ inject biến PORT; code phải listen(process.env.PORT)
EXPOSE 8080      # tuỳ chọn, không bắt buộc nhưng giúp self-document

# Khởi chạy server
CMD ["node", "dist/index.js"]

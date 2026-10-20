# syntax=docker/dockerfile:1
# Deploy additions for luodaint self-hosting (upstream marclou/mailcheap has no Dockerfile).

FROM node:22-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM deps AS build
WORKDIR /app
COPY . .
# Values read at build time (docs, llms.txt, CSP config). Runtime env can override APP_URL behaviour.
ARG APP_URL=http://localhost:3000
ENV APP_URL=$APP_URL
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

FROM node:22-alpine AS run
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/next.config.mjs ./next.config.mjs
COPY --from=build /app/instrumentation.js ./instrumentation.js
COPY --from=build /app/proxy.js ./proxy.js
EXPOSE 3000
CMD ["npm", "run", "start"]

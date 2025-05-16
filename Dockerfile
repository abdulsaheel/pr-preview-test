# 1. Build stage
FROM node:22-alpine AS builder
WORKDIR /app

RUN corepack enable && corepack prepare yarn@4.5.1 --activate
RUN echo "nodeLinker: node-modules" > .yarnrc.yml

COPY package.json yarn.lock ./
RUN yarn install

COPY . .
ENV PATH="/app/node_modules/.bin:${PATH}"
RUN yarn build

# 2. Serve using nginx
FROM nginx:alpine

# Clean default nginx html content
RUN rm -rf /usr/share/nginx/html/*

# Copy built frontend
COPY --from=builder /app/dist /usr/share/nginx/html

# Generate nginx config dynamically
RUN printf "server {\n\
    listen 80;\n\
    server_name _;\n\
\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    location / {\n\
        try_files \$uri \$uri/ /index.html;\n\
    }\n\
\n\
    location ~* \\\\.(?:ico|css|js|gif|jpe?g|png|woff2?|eot|ttf|svg|otf)\$ {\n\
        expires 6M;\n\
        access_log off;\n\
        add_header Cache-Control \"public\";\n\
    }\n\
}\n" > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
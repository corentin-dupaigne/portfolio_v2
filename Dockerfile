FROM hugomods/hugo:0.147.0 AS builder

WORKDIR /src
COPY . .
RUN hugo --minify --baseURL "/"

FROM nginx:alpine

COPY --from=builder /src/public /usr/share/nginx/html

EXPOSE 80

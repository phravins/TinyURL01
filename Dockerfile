# Build stage
FROM erlang:26-alpine AS builder

WORKDIR /build
COPY . .

# Install build dependencies
RUN apk add --no-cache git gcc libc-dev make

# Build release
RUN rebar3 as prod tar

# Extract release
RUN mkdir -p /opt/rel
RUN tar -zxvf _build/prod/rel/shortener_release/shortener_release-0.1.0.tar.gz -C /opt/rel

# Run stage
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs libstdc++ postgresql-client

WORKDIR /app
COPY --from=builder /opt/rel ./

# Create non-root user
RUN adduser -D shortener && chown -R shortener:shortener /app
USER shortener

ENV RELX_OUT_FILE_PATH=/tmp
EXPOSE 8080

CMD ["/app/bin/shortener_release", "foreground"]

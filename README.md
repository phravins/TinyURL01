# Erlang URL Shortener

A production-ready URL shortener built with Erlang/OTP, Cowboy, and PostgreSQL.

## Features
- **OTP Architecture**: Structured into modular apps (`api`, `core`, `storage`, `analytics`).
- **Base62 Encoding**: Short and unique URL codes.
- **Cache-Aside**: High performance reads using ETS cache.
- **Asynchronous Analytics**: Clicks are tracked via GenServer buffer and periodically flushed to PostgreSQL.
- **Dockerized**: Ready for deployment with multi-stage Docker build.

## Prerequisites
- Erlang >= 26
- Rebar3
- PostgreSQL or Docker Compose

## Running Locally (Docker)

The easiest way to run the application and its database:

```bash
docker-compose up --build
```
This will start PostgreSQL (initialized with schemas) and the Erlang application on port 8080.

## API Endpoints

### Shorten URL
```bash
curl -X POST http://localhost:8080/api/shorten \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com/very/long/url"}'
```

### Redirect
```bash
curl -i http://localhost:8080/<short-code>
```

### Stats
```bash
curl http://localhost:8080/api/stats/<short-code>
```

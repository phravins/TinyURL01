# Erlang/OTP URL Shortener — Advanced Edition

A **production-ready, feature-rich URL shortener** built with Erlang/OTP, Cowboy HTTP server, and PostgreSQL. Designed for high concurrency, horizontal scalability, and operational simplicity.

---

## Features

| Feature | Description |
|---|---|
|  **Base62 Short Codes** | Unique 6-char codes generated from system time |
|  **Password-Protected Links** | SHA-256 hashed, HTML unlock form included |
|  **Expiring Links (TTL)** | Configurable expiry, auto-cleanup every 60s |
|  **Bulk Shortening** | Shorten an array of URLs in a single request |
|  **Geo-Tracking** | Country/city logged per click via ip-api.com |
|  **Webhook Notifications** | Fire an HTTP POST to your URL on every click |
|  **Link Preview** | Fetches `<title>`, OpenGraph tags from destinations |
|  **QR Code Generation** | Instant QR code for any short URL |
|  **Rate Limiting** | 20 req/min per IP (ETS sliding window) |
|  **Admin Dashboard API** | Stats, URL list, per-link analytics, delete — API-key protected |
|  **Distributed Erlang** | Cache invalidation broadcast across nodes via `pg` process groups |
|  **ETS Cache-Aside** | In-memory ETS cache backing every redirect (sub-ms lookups) |
|  **Cross-Platform CLI** | Full-featured CLI for Windows, Linux, and macOS |
|  **Elegant Web UI** | Glassmorphism SPA served directly from Erlang (no Node.js needed) |

---

## Quickstart (Docker)

```bash
git clone <repo>
docker-compose up --build
```

The database schema is applied automatically on first run.

---

## API Reference

### `POST /api/shorten` — Shorten a URL

```bash
# Simple
curl -X POST http://localhost:8080/api/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/long/path"}'

# With all options
curl -X POST http://localhost:8080/api/shorten \
  -H "Content-Type: application/json" \
  -d '{
    "url":         "https://example.com",
    "custom_code": "mycode",
    "ttl":         3600,
    "password":    "s3cr3t",
    "webhook_url": "https://yoursite.com/hooks/click"
  }'
```

**Response:**
```json
{
  "short_url":  "http://localhost:8080/Ab3k9Q",
  "short_code": "Ab3k9Q",
  "expires_at": "2026-03-13T09:00:00Z",
  "protected":  false
}
```

---

### `POST /api/shorten` — Bulk Mode

```bash
curl -X POST http://localhost:8080/api/shorten \
  -H "Content-Type: application/json" \
  -d '{"urls": ["https://example.com", "https://google.com"]}'
```

---

### `GET /:code` — Redirect

```bash
curl -I http://localhost:8080/Ab3k9Q
# → HTTP/1.1 302 Found  Location: https://example.com
```

If the link is **password-protected**, you'll be redirected to `/unlock/:code` — an HTML unlock form.

---

### `POST /api/unlock/:code` — Unlock a Protected Link

```bash
curl -X POST http://localhost:8080/api/unlock/Ab3k9Q \
  -H "Content-Type: application/json" \
  -d '{"password": "s3cr3t"}'
```

---

### `GET /api/stats/:code` — Click Statistics

```bash
curl http://localhost:8080/api/stats/Ab3k9Q
```

---

### `GET /api/preview/:code` — Link Preview (Title, OG tags)

```bash
curl http://localhost:8080/api/preview/Ab3k9Q
```

---

### `GET /api/qr/:code` — QR Code

Navigate to `http://localhost:8080/api/qr/Ab3k9Q` in your browser — you'll be redirected to a QR code image.

---

### Admin Endpoints (require `X-Admin-Token` header)

```bash
# Global stats
curl http://localhost:8080/api/admin/stats -H "X-Admin-Token: change_me_in_production"

# Paginated URL list
curl "http://localhost:8080/api/admin/urls?page=1&limit=10" -H "X-Admin-Token: ..."

# Per-link click events (last 100)
curl http://localhost:8080/api/admin/analytics/Ab3k9Q -H "X-Admin-Token: ..."

# Delete a link
curl -X DELETE http://localhost:8080/api/admin/urls/Ab3k9Q -H "X-Admin-Token: ..."
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_USER` | `postgres` | Database user |
| `DB_PASS` | `postgres` | Database password |
| `DB_NAME` | `shortener` | Database name |
| `ADMIN_TOKEN` | `admin_secret` | Admin API auth token |
| `GEOIP_API_URL` | *(ip-api.com)* | Override GeoIP endpoint |

---

## Running Locally Without Docker

**Prerequisites:** Erlang ≥ 26, Rebar3, PostgreSQL

```bash
# 1. Create the database and apply the schema
psql -U postgres -c "CREATE DATABASE shortener;"
psql -U postgres -d shortener -f apps/shortener_storage/priv/schema.sql

# 2. Start the Erlang shell
rebar3 shell
```

---

## Horizontal Scaling

Multiple Erlang nodes can be connected using short/long names. Cache eviction events
are broadcast across all connected nodes via `pg` (Erlang process groups):

```bash
# Node 1
erl -sname shortener1 -setcookie shortener_secret_cookie ...

# Node 2
erl -sname shortener2 -setcookie shortener_secret_cookie ...
net_adm:ping('shortener1@hostname').
```

---

## Building a Production Release

```bash
rebar3 as prod tar
# Output: _build/prod/rel/shortener_release/shortener_release-0.2.0.tar.gz
```

---

## 💻 CLI — Command Line Interface

A full-featured CLI is included in `cli/` and works on **Windows, Linux, and macOS**.

### Prerequisites

Erlang ≥ 26 must be on your `PATH`. Then:

| OS | Install |
|---|---|
| macOS | `brew install erlang` |
| Ubuntu | `sudo apt-get install erlang` |
| Fedora | `sudo dnf install erlang` |
| Windows | [erlang.org/downloads](https://www.erlang.org/downloads) |

### Install

**Linux / macOS:**
```bash
bash cli/install.sh
```

**Windows (Admin cmd):**
```bat
cli\install.bat
```

**Windows (PowerShell, no install):**
```powershell
.\cli\shortener.ps1 shorten https://example.com
```

### Configure

```bash
shortener config set --host localhost --port 8080 --token change_me_in_production
```

### Examples

```bash
# Shorten
shortener shorten https://example.com

# Shorten with TTL + password
shortener shorten https://example.com --ttl 86400 --password secret

# Bulk shorten
shortener bulk https://a.com https://b.com https://c.com

# Stats
shortener stats Ab3k9Q

# Link preview (title / OG tags)
shortener preview Ab3k9Q

# QR Code URL
shortener qr Ab3k9Q

# Open Web UI
shortener web

# Admin
shortener admin stats
shortener admin list --page 1 --limit 20
shortener admin analytics Ab3k9Q
shortener admin delete Ab3k9Q
```

See `cli/README.md` for the full reference.


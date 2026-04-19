# Erlang/OTP URL Shortener

A **production-ready, feature-rich URL shortener** built with Erlang/OTP, Cowboy HTTP server, and PostgreSQL. Designed for high concurrency, horizontal scalability, and operational simplicity — with a full cross-platform CLI included.

---

## Features

| Feature | Description |
|---|---|
| **Base62 Short Codes** | Unique 6-char codes generated from system time |
| **Password-Protected Links** | SHA-256 hashed, HTML unlock form included |
| **Expiring Links (TTL)** | Configurable expiry, auto-cleanup every 60s |
| **Bulk Shortening** | Shorten an array of URLs in a single request |
| **Geo-Tracking** | Country/city logged per click via ip-api.com |
| **Webhook Notifications** | Fire an HTTP POST to your URL on every click |
| **Link Preview** | Fetches `<title>`, OpenGraph tags from destinations |
| **QR Code Generation** | Instant QR code for any short URL |
| **Rate Limiting** | 20 req/min per IP (ETS sliding window) |
| **Admin Dashboard API** | Stats, URL list, per-link analytics, delete — API-key protected |
| **Distributed Erlang** | Cache invalidation broadcast across nodes via `pg` process groups |
| **ETS Cache-Aside** | In-memory ETS cache backing every redirect (sub-ms lookups) |
| **Cross-Platform CLI** | Full-featured CLI for Windows, Linux, and macOS |
| **PostgreSQL DB Admin CLI** | Direct DB access: query, search, shell, stats — all from the CLI |
| **CLI Auto-Update** | `shortener update` pulls the latest CLI binary from GitHub |
| **Elegant Web UI** | Glassmorphism SPA served directly from Erlang (no Node.js needed) |

---

## Quickstart (Docker)

```bash
git clone <repo>
docker-compose up --build
```

The database schema is applied automatically on first run.  
Web UI → `http://localhost:8080`  
PostgreSQL is exposed on host port **5433** (mapped from container port 5432).

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

### `GET /api/preview/:code` — Link Preview

```bash
curl http://localhost:8080/api/preview/Ab3k9Q
```

---

### `GET /api/qr/:code` — QR Code

Navigate to `http://localhost:8080/api/qr/Ab3k9Q` in your browser to get a QR code image.

---

### Admin Endpoints (require `X-Admin-Token` header)

```bash
# Global stats
curl http://localhost:8080/api/admin/stats \
  -H "X-Admin-Token: change_me_in_production"

# Paginated URL list
curl "http://localhost:8080/api/admin/urls?page=1&limit=10" \
  -H "X-Admin-Token: change_me_in_production"

# Per-link click events (last 100)
curl http://localhost:8080/api/admin/analytics/Ab3k9Q \
  -H "X-Admin-Token: change_me_in_production"

# Delete a link
curl -X DELETE http://localhost:8080/api/admin/urls/Ab3k9Q \
  -H "X-Admin-Token: change_me_in_production"
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
| `PORT` | `8080` | HTTP server port |
| `ADMIN_TOKEN` | `change_me_in_production` | Admin API auth token |
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

Multiple Erlang nodes can be connected. Cache eviction events are broadcast across all connected nodes via `pg` (Erlang process groups):

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

## CLI — Command Line Interface

A full-featured CLI (`cli/shortener_cli`) works on **Windows**, **Linux**, and **macOS** — powered by Erlang escript with zero runtime dependencies.

### Installation

#### Option 1 — Remote 1-Liner (recommended)

These commands automatically detect and install Erlang if missing, then install the CLI:

**Linux / macOS / Windows Git Bash:**
```bash
curl -fsSL https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.sh | bash
```

**Windows (PowerShell — run as Administrator):**
```powershell
iwr https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.ps1 -useb | iex
```

#### Option 2 — Local Install (from project root)

**Linux / macOS:**
```bash
cd cli && bash install.sh
# Custom prefix:  bash install.sh --prefix ~/.local
```

**Windows (run as Administrator):**
```bat
cd cli
install.bat
```

#### Option 3 — No Install (run directly)

**Windows batch:**
```bat
cli\shortener.bat shorten https://example.com
```

**Windows PowerShell:**
```powershell
cli\shortener.ps1 shorten https://example.com
```

---

### Configuration

Point the CLI at your running server and (optionally) configure direct database access:

```bash
# API server settings
shortener config set --host localhost --port 8080 --token YOUR_ADMIN_TOKEN

# Database settings (for db commands — use port 5433 when connecting to Docker)
shortener config set --db-host localhost --db-port 5433 \
  --db-user postgres --db-pass postgres --db-name shortener

# Show all current settings
shortener config show
```

Config is saved to `~/.shortener.conf`.

---

### Core Commands

#### Shorten a URL

```bash
shortener shorten https://example.com

# With options
shortener shorten https://example.com \
  --custom mycode \
  --ttl 3600 \
  --password secret \
  --webhook https://webhook.site/xxx
```

#### Bulk Shorten

```bash
shortener bulk https://example.com https://github.com https://erlang.org
```

#### Stats

```bash
shortener stats Ab3k9Q
```

#### Link Preview (title / OG tags)

```bash
shortener preview Ab3k9Q
```

#### QR Code

```bash
shortener qr Ab3k9Q
```

---

### Admin API Commands

These require the admin token to be configured.

```bash
shortener admin stats
shortener admin list --page 1 --limit 20
shortener admin analytics Ab3k9Q
shortener admin delete Ab3k9Q
```

---

### DB Commands — Direct PostgreSQL Access

These commands connect directly to PostgreSQL using `psql`. Requires the PostgreSQL client tools installed on your machine (`psql --version` must work). Configure with `shortener config set --db-host ...`.

| Command | Description |
|---|---|
| `shortener db status` | Check DB connection, show PostgreSQL version |
| `shortener db stats` | Row counts for `urls`, `analytics`, `url_meta` tables |
| `shortener db urls [--limit N]` | List most recent URLs directly from DB |
| `shortener db analytics [--code CODE] [--limit N]` | Raw click events |
| `shortener db search <term>` | Full-text search across URLs and short codes |
| `shortener db shell` | Open an interactive `psql` session |
| `shortener db query "<SQL>"` | Run any raw SQL query |
| `shortener db config set` | Save DB connection params |
| `shortener db config show` | Show DB connection params |

**Examples:**

```bash
# Check connection
shortener db status

# View table sizes
shortener db stats

# List 50 most recent URLs
shortener db urls --limit 50

# Click events for a specific short code
shortener db analytics --code Ab3k9Q --limit 100

# Search for URLs containing "github"
shortener db search github

# Open interactive psql shell
shortener db shell

# Run custom SQL
shortener db query "SELECT short_code, click_count FROM urls ORDER BY click_count DESC LIMIT 10;"

# Configure DB connection (Docker exposes on 5433)
shortener config set --db-host localhost --db-port 5433
```

**Installing psql client tools (if not already installed):**

```bash
# Ubuntu / Debian
sudo apt install postgresql-client

# macOS
brew install libpq && brew link --force libpq

# Windows
# Download from https://www.postgresql.org/download/windows/
# (PostgreSQL installer includes psql)
```

---

### Web UI Commands

```bash
# Open web UI in browser (checks server is running first)
shortener web

# Start the real Erlang server (must be run from project root)
shortener start

# Start the Python mock server for UI testing (no Docker/Postgres needed)
# Must be run from project root
shortener webmock
```

> `shortener web` checks that the server is reachable before opening the browser.  
> If it's not running, it tells you exactly which command to use to start it.

---

### Auto-Update

```bash
shortener update
```

Connects to GitHub, compares the remote version against the installed version, and replaces the CLI binary in-place if a newer version is available. On Unix, `chmod +x` is applied automatically.

```
  ↑  Checking for updates  (current: v2.1.0)
  ✦  New version available: v2.2.0
  ↓  Writing update to /usr/local/bin/shortener ...
  ✓  Updated to v2.2.0  Restart your terminal to apply.
```

---

### Version Info

```bash
shortener version
shortener --version
```

---

### All Commands at a Glance

```bash
shortener help
```

```
  shortener v2.1.0  -- URL Shortener CLI
  --------------------------------------------------------

  CORE
    shorten <url> --custom CODE --ttl SEC --password PWD  Shorten a URL
    bulk <url...>                                         Shorten multiple URLs at once

  INFO
    stats <code>                                          Click statistics
    preview <code>                                        Preview destination (OG data)
    qr <code>                                             Get QR code image URL

  ADMIN API  requires --token
    admin stats                                           Global server stats
    admin list --page N --limit N                         Paginated URL list
    admin delete <code>                                   Delete a short URL
    admin analytics <code>                                Click analytics

  DB  PostgreSQL direct access
    db status                                             Check DB connection
    db stats                                              Tables & row counts
    db urls [--limit N]                                   List URLs from DB
    db analytics [--code C] [--limit N]                   Click events
    db search <term>                                      Search URLs
    db shell                                              Open psql session
    db query "<SQL>"                                      Run raw SQL

  CONFIG
    config set  --host H --port P --token T --db-host H ...  Save settings
    config show                                               Show settings

  OTHER
    start        Start local server (rebar3)
    web          Open web UI in browser
    webmock      Start Python mock server
    update       Update CLI to latest version
    version      Show version info
```

---

### Example Output

```
$ shortener shorten https://erlang.org

  ✓  http://localhost:8080/4Ab9kZ

$ shortener stats 4Ab9kZ

  Code              4Ab9kZ
  URL               https://erlang.org
  Clicks            17
  Created           2026-03-12T09:00:00Z
  Expires           --
  Custom            no

$ shortener db urls --limit 3

  URLs (latest 3)

  Code            Long URL                          Clicks    Expires
  ----------------------------------------------------------------
  4Ab9kZ          https://erlang.org                17        --
  mycode          https://example.com               4         2026-04-01
  Xz9pQ1          https://github.com/phravins       2         --

$ shortener db stats

  Database Stats  localhost:5433/shortener

   table_name | rows
  ------------+------
   URLs        | 142
   analytics   | 891
   url_meta    | 98
```

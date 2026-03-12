# Auto-configure git identity locally if not set globally
$username = git config --global user.name
if (-not $username) {
    git config --local user.name "Antigravity Assistant"
    git config --local user.email "antigravity@gemini.local"
}

git init
git branch -M main

# Build Configuration
git add rebar.config
git commit -m "Configure rebar3 build dependencies and release profiles"

git add config/sys.config
git commit -m "Configure OTP application environment variables for database and server"

git add config/vm.args
git commit -m "Configure Erlang VM arguments for distributed nodes and async threads"

# Core OTP Application
git add apps/shortener_core/src/shortener_core.app.src
git add apps/shortener_core/src/shortener_core_app.erl
git add apps/shortener_core/src/shortener_core_sup.erl
git commit -m "Initialize core logic OTP application and supervisor"

git add apps/shortener_core/src/shortener_base62.erl
git commit -m "Implement Base62 encoding and decoding logic"

git add apps/shortener_core/src/shortener_validator.erl
git commit -m "Add validation logic for URLs and custom short codes"

git add apps/shortener_core/src/shortener_core_api.erl
git commit -m "Expose main API for core shortening logic"

git add apps/shortener_core/src/shortener_metadata.erl
git commit -m "Implement asynchronous target URL metadata scraper"

# Storage OTP Application
git add apps/shortener_storage/src/shortener_storage.app.src
git add apps/shortener_storage/src/shortener_storage_app.erl
git add apps/shortener_storage/src/shortener_storage_sup.erl
git commit -m "Initialize storage OTP application, supervisor, and child specs"

git add apps/shortener_storage/priv/schema.sql
git commit -m "Define PostgreSQL database schema and indexes"

git add apps/shortener_storage/src/shortener_postgres.erl
git commit -m "Implement PostgreSQL connection pool worker using poolboy"

git add apps/shortener_storage/src/shortener_cache.erl
git commit -m "Implement ETS-backed in-memory cache GenServer"

git add apps/shortener_storage/src/shortener_distributed_cache.erl
git commit -m "Add distributed cache invalidation across Erlang nodes"

git add apps/shortener_storage/src/shortener_expiry_server.erl
git commit -m "Implement periodic cleanup task for expired URLs"

git add apps/shortener_storage/src/shortener_db.erl
git commit -m "Create abstraction layer for database and cache operations"

# Analytics OTP Application
git add apps/shortener_analytics/src/shortener_analytics.app.src
git add apps/shortener_analytics/src/shortener_analytics_app.erl
git add apps/shortener_analytics/src/shortener_analytics_sup.erl
git commit -m "Initialize analytics OTP application and supervisor"

git add apps/shortener_analytics/src/shortener_geoip.erl
git commit -m "Implement IP geolocation lookup using external API"

git add apps/shortener_analytics/src/shortener_webhook.erl
git commit -m "Implement asynchronous webhook notification dispatcher"

git add apps/shortener_analytics/src/shortener_analytics_worker.erl
git commit -m "Create GenServer to buffer and flush analytics click events"

# API OTP Application
git add apps/shortener_api/src/shortener_api.app.src
git add apps/shortener_api/src/shortener_api_app.erl
git add apps/shortener_api/src/shortener_api_sup.erl
git commit -m "Initialize HTTP API application with Cowboy web server"

git add apps/shortener_api/src/shortener_rate_limiter.erl
git commit -m "Implement sliding-window IP rate limiter using ETS"

git add apps/shortener_api/src/shortener_handler_shorten.erl
git commit -m "Create Cowboy handler for HTTP POST URL shortening"

git add apps/shortener_api/src/shortener_handler_redirect.erl
git commit -m "Create Cowboy handler for HTTP GET redirection and tracking"

git add apps/shortener_api/src/shortener_handler_stats.erl
git commit -m "Create Cowboy handler for retrieving URL statistics"

git add apps/shortener_api/src/shortener_handler_qr.erl
git commit -m "Create Cowboy handler for generating QR code redirections"

git add apps/shortener_api/src/shortener_handler_preview.erl
git commit -m "Create Cowboy handler for fetching target URL previews"

git add apps/shortener_api/src/shortener_handler_unlock.erl
git commit -m "Create Cowboy handlers for password-protected link unlock forms"

git add apps/shortener_api/src/shortener_handler_admin.erl
git commit -m "Create Cowboy handlers for administrative dashboards and actions"

# Docker and Setup
git add Dockerfile
git commit -m "Add multi-stage Dockerfile for production releases"

git add docker-compose.yml
git commit -m "Add Docker Compose configuration for local development"

git add README.md
git commit -m "Add comprehensive project documentation and setup guides"

# CLI
git add cli/shortener_cli
git commit -m "Implement cross-platform CLI tool using Erlang escript"

git add cli/shortener.bat
git add cli/shortener.ps1
git commit -m "Add CLI launcher wrappers for Windows CMD and PowerShell"

git add cli/install.bat
git add cli/install.sh
git commit -m "Add installation scripts for Windows, Linux, and macOS"

git add cli/README.md
git commit -m "Add dedicated documentation for using the CLI tool"

# Catch-all
git add .
git commit -m "Add any remaining unscoped files and metadata"

# Push to remote
git remote add origin https://github.com/phravins/TinyURL01.git
git push -u origin main --force

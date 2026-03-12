# shortener CLI

Cross-platform command-line tool for the URL Shortener.  
Works on **Windows**, **Linux**, and **macOS** — powered by Erlang escript.

---

## Requirements

- **Erlang** (≥ 26) must be installed and on your `PATH`.

| OS | Install Command |
|---|---|
| macOS | `brew install erlang` |
| Ubuntu/Debian | `sudo apt-get install erlang` |
| Fedora/RHEL | `sudo dnf install erlang` |
| Windows | [Download installer](https://www.erlang.org/downloads) |

---

## Installation

### Linux / macOS

```bash
cd <project_root>/cli
bash install.sh
```

This copies the escript to `/usr/local/bin/shortener`.  
Use a custom prefix: `bash install.sh --prefix ~/.local`

### Windows (batch)

Run **as Administrator**:

```bat
cd cli
install.bat
```

Or run directly without installing:

```bat
cli\shortener.bat shorten https://example.com
```

### Windows (PowerShell)

```powershell
cd cli
.\shortener.ps1 shorten https://example.com
```

---

## Configuration

Point the CLI at a running server:

```bash
shortener config set --host localhost --port 8080 --token change_me_in_production
shortener config show
```

Config is saved to `~/.shortener.conf`.

---

## Commands

### Shorten a URL

```bash
shortener shorten https://example.com
```

With options:

```bash
shortener shorten https://example.com \
  --custom mycode \
  --ttl 3600 \
  --password secret \
  --webhook https://webhook.site/xxx
```

### Bulk Shorten

```bash
shortener bulk https://example.com https://github.com https://erlang.org
```

### Get Stats

```bash
shortener stats Ab3k9Q
```

### Link Preview (title / OG tags)

```bash
shortener preview Ab3k9Q
```

### QR Code URL

```bash
shortener qr Ab3k9Q
```

### Open Web UI

```bash
shortener web
```

### Run WebMock Server (UI Testing)

Launch a local mock server and open the UI in a browser without needing Docker/PostgreSQL:

```bash
# MUST be run from the project root directory!
shortener webmock
```

### Admin Commands

```bash
shortener admin stats
shortener admin list --page 1 --limit 20
shortener admin analytics Ab3k9Q
shortener admin delete Ab3k9Q
```

---

## Example Output

```
$ shortener shorten https://erlang.org

  Short URL  : http://localhost:8080/4Ab9kZ
  Expires    : —
  Protected  : no
```

```
$ shortener stats 4Ab9kZ

  Short Code  : 4Ab9kZ
  Long URL    : https://erlang.org
  Clicks      : 17
  Created     : 2026-03-12T09:00:00Z
  Expires     : —
  Custom      : no
```

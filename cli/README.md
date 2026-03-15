# shortener CLI

Cross-platform command-line tool for the URL Shortener.  
Works on **Windows**, **Linux**, and **macOS** — powered by Erlang escript.

---

## Requirements

Just an internet connection! The installation scripts below will **automatically download and configure everything**, including the Erlang runtime environment, with zero manual prerequisites required.

---

## Zero-Dependency 1-Liner Installation

### Linux / macOS

Automatically uses `apt-get`, `brew`, `dnf`, or `pacman` behind the scenes:

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

### Quick Install (Remote)

The remote installers now include:
- **Automatic Erlang Detection**: Checks for Erlang and installs the newest version (OTP 28.4.1) if missing.
- **Cross-Platform Support**: Works on Linux, macOS, and Windows (PowerShell or Git Bash).
- **Network Resilience**: Automatic retries and DNS recovery for faster, more reliable downloads.

#### Linux / macOS / Windows Git Bash
```bash
curl -fsSL https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.sh | bash
```

#### Windows PowerShell (As Administrator)
```powershell
iwr https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.ps1 -useb | iex
```

---

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

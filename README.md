# Pdf on Rails

A free, no-signup-required PDF toolkit (merge, split, rotate, compress, convert, OCR, and
more) built in Ruby on Rails — a spiritual successor for former iLovePDF users, and a
technical demo of Rails + Hotwire.

Guest mode is the default: upload, process, download, no account needed. Signing up is
optional and only unlocks history and higher limits.

## Status

Implemented so far:

- Rails 8.1 app with PostgreSQL, Tailwind CSS (via `tailwindcss-rails`, no Node.js needed),
  and Hotwire (Turbo + Stimulus via importmap)
- Devise authentication skeleton (`User` model, sign in/up), never required to use the app
- Spanish by default, with an English toggle (session-persisted); Devise's own views/flash
  messages are translated for free via `devise-i18n`
- **Tier 1** (synchronous, no persistence — upload, process, download in one request):
  Merge, Split (multi-range, ZIP for multiple outputs), Rotate, Delete pages
- **Tier 2 sync tools**: Compress (Ghostscript), Watermark, Protect/Unlock (hexapdf
  encryption), JPG ↔ PDF (Ghostscript rasterization + hexapdf image embedding)
- **Tier 2 async tools**: OCR (Tesseract via `rtesseract`) and Office → PDF (LibreOffice
  headless) run as Solid Queue background jobs, with a status page that live-updates via
  Turbo Streams (`broadcasts_refreshes` + `turbo_refreshes_with method: :morph`) — no Redis,
  Solid Queue/Cache/Cable all ride on the same Postgres database
- A `ProcessedFile` model (owned by `user_id` or a session-based `guest_token`) tracks
  async job status and holds the source/result files via ActiveStorage; a recurring
  `FileCleanupJob` purges guest files after 30 minutes (registered users keep theirs, since
  "history" is the actual signup incentive)

Not yet implemented: registered-user history UI and a Sidekiq-style admin dashboard for
Solid Queue. See `prompt_ilovepdf_rails_en.md` for the full spec.

## Tech stack

- Ruby 3.4.10, Rails 8.1, PostgreSQL
- Tailwind CSS (standalone binary, no Node.js/Yarn dependency)
- Hotwire (Turbo + Stimulus) via importmap-rails
- Devise for optional authentication, `devise-i18n` + `rails-i18n` for translations
- `hexapdf` (pure Ruby) for merge/split/rotate/delete/watermark/encrypt/decrypt and
  embedding JPGs into PDFs
- Ghostscript (shelled out to) for PDF compression and PDF → JPG rasterization
- `rtesseract` + Tesseract OCR for text extraction
- LibreOffice headless for Office → PDF conversion
- Solid Queue for background jobs (OCR, Office conversion, guest file cleanup) — no Redis

## Local setup (WSL2 + Ubuntu)

This app is developed inside WSL2 (Ubuntu), even though the deploy target is a
Windows/Docker host, because Rails tooling assumes a Linux/macOS environment.

1. Install WSL2 + Ubuntu: `wsl --install -d Ubuntu` (from an elevated Windows terminal),
   reboot if prompted.
2. Inside Ubuntu, install system deps:
   ```
   sudo apt-get update
   sudo apt-get install -y build-essential curl git libssl-dev libreadline-dev zlib1g-dev \
     libyaml-dev libpq-dev postgresql postgresql-contrib \
     ghostscript tesseract-ocr tesseract-ocr-spa tesseract-ocr-eng libreoffice
   ```
   (LibreOffice is a large install; grab a coffee.)
3. Install Ruby via [rbenv](https://github.com/rbenv/rbenv):
   ```
   git clone https://github.com/rbenv/rbenv.git ~/.rbenv
   git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
   # wire rbenv into your shell init, then:
   rbenv install 3.4.10
   rbenv global 3.4.10
   gem install bundler rails --no-document
   ```
4. Start Postgres and create a superuser role matching your Linux username:
   ```
   sudo service postgresql start
   sudo -u postgres psql -c "CREATE ROLE $USER WITH LOGIN SUPERUSER CREATEDB;"
   ```
5. Install gems and set up the databases (primary + the Solid Queue/Cache/Cable schemas,
   which share the same physical database in development):
   ```
   bundle install
   bin/rails db:prepare
   bin/rails db:schema:load:queue db:schema:load:cache db:schema:load:cable
   ```
6. Run the app: `bin/dev` (starts Puma, the Solid Queue worker, and the Tailwind watcher),
   then visit `http://localhost:3000`.

   Note: unlike Postgres, Solid Queue's worker isn't a persistent OS service — every time
   you come back to a cold WSL session, `sudo service postgresql start` and `bin/dev` (which
   includes the worker) both need to run again.

## Deploying

Self-hosted via Docker Compose (`docker-compose.yml`): a `db` (Postgres 18) container, a
`web` container (built from `Dockerfile`, runs Puma with the Solid Queue worker/scheduler
in-process via `SOLID_QUEUE_IN_PUMA=true` — no separate worker container needed at this
scale), and a `cloudflared` container exposing it to the internet via a Cloudflare quick
tunnel (no domain or account needed; prints a random public HTTPS URL to its own logs, at
the cost of that URL changing on every restart — a named tunnel with a stable hostname is
the upgrade path once a permanent domain is in the picture).

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (WSL2 backend).
2. `copy .env.example .env` and fill in `RAILS_MASTER_KEY` (from `config/master.key`) and a
   `POSTGRES_PASSWORD`.
3. `docker compose build && docker compose up -d`, then `docker compose logs cloudflared`
   for the public URL.

One gotcha worth knowing if you ever touch `docker-compose.yml`: Postgres 18's official
image switched to mounting its data directory at `/var/lib/postgresql` itself (not
`.../data`, the pre-18 convention still shown in most examples) — mounting at the old path
makes the container refuse to start.

## Running tests

```
bin/rails test
bin/rails test:system
```

`test:system` needs a real Chrome install (Selenium's Selenium Manager auto-downloads a
matching chromedriver). On Ubuntu/WSL, install Google Chrome directly rather than the
`chromium` apt package — that one resolves to a snap, and Chrome-in-a-snap's confinement
breaks Selenium with `session not created: DevToolsActivePort file doesn't exist`:
```
wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get install -y /tmp/google-chrome.deb
```

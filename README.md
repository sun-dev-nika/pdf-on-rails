# Pdf on Rails

A free, no-signup-required PDF toolkit (merge, split, rotate, compress, convert, OCR, and
more) built in Ruby on Rails — a spiritual successor for former iLovePDF users, and a
technical demo of Rails + Hotwire.

Guest mode is the default: upload, process, download, no account needed. Signing up is
optional and only unlocks history and higher limits.

## Status

This is the initial project scaffold. Implemented so far:

- Rails 8.1 app with PostgreSQL, Tailwind CSS (via `tailwindcss-rails`, no Node.js needed),
  and Hotwire (Turbo + Stimulus via importmap)
- Devise authentication skeleton (`User` model, sign in/up), never required to use the app
- Minimal landing page proving the stack boots end-to-end

Not yet implemented: any PDF operations (merge/split/rotate/etc.), background jobs
(Sidekiq/Solid Queue), file upload/cleanup, OCR, Office conversion, or deployment config.
See `prompt_ilovepdf_rails_en.md` for the full product spec this is being built against.

## Tech stack

- Ruby 3.4.10, Rails 8.1
- PostgreSQL
- Tailwind CSS (standalone binary, no Node.js/Yarn dependency)
- Hotwire (Turbo + Stimulus) via importmap-rails
- Devise for optional authentication

## Local setup (WSL2 + Ubuntu)

This app is developed inside WSL2 (Ubuntu), even though the deploy target is a
Windows/Docker host, because Rails tooling assumes a Linux/macOS environment.

1. Install WSL2 + Ubuntu: `wsl --install -d Ubuntu` (from an elevated Windows terminal),
   reboot if prompted.
2. Inside Ubuntu, install system deps:
   ```
   sudo apt-get update
   sudo apt-get install -y build-essential curl git libssl-dev libreadline-dev zlib1g-dev \
     libyaml-dev libpq-dev postgresql postgresql-contrib
   ```
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
5. Install gems and set up the database:
   ```
   bundle install
   bin/rails db:create db:migrate
   ```
6. Run the app: `bin/dev` (starts Puma + the Tailwind watcher), then visit
   `http://localhost:3000`.

## Running tests

```
bin/rails test
```

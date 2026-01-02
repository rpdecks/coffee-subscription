# Pre-Launch Infrastructure (Fly.io) — Minimal Baseline

This app is currently pre-launch / low-traffic. The goal is to reduce cost and operational complexity while keeping Redis + Sidekiq easy to re-enable later.

## Current Pre-Launch Defaults

- **ActiveJob**: uses `:async` unless explicitly enabled.
- **ActionCable**: uses `async` unless explicitly enabled.
- **Redis**: not required at runtime.
- **Sidekiq**: not required at runtime.

These defaults are controlled via environment variables.

## How To Disable Redis + Sidekiq (Production)

1. **Scale down process groups**

- Keep one web machine:

  `flyctl scale count -a coffee-production app=1`

- Disable workers:

  `flyctl scale count -a coffee-production sidekiq=0`

2. **Unset Redis secret (optional, recommended for clarity)**

If Redis is not being used at runtime, remove it:

- `flyctl secrets unset -a coffee-production REDIS_URL`

## How To Re-Enable Redis + Sidekiq Later

1. **Restore Redis**

- Recreate an Upstash Redis (or other Redis) and set:

  `flyctl secrets set -a coffee-production REDIS_URL=redis://...`

- Enable Redis usage for ActionCable:

  `flyctl secrets set -a coffee-production ENABLE_REDIS=true`

2. **Enable Sidekiq workers + ActiveJob adapter**

- Enable Sidekiq adapter:

  `flyctl secrets set -a coffee-production ENABLE_SIDEKIQ=true`

- Scale workers back up:

  `flyctl scale count -a coffee-production sidekiq=1`

3. **Deploy**

- `flyctl deploy -a coffee-production`

## Notes / Tradeoffs

- `:async` jobs do **not** survive restarts and are process-local. This is acceptable pre-launch but not ideal once you need guaranteed retries (e.g., Stripe webhook retries, recurring billing, scheduled order generation).
- `async` ActionCable is single-process only. This is fine with a single web machine but is not suitable for multi-machine realtime features.

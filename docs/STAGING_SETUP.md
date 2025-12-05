# Fly.io Environment Setup

## Production Resources

**App:** `coffee-production`

- URL: https://acercoffee.com (https://coffee-production.fly.dev)
- Region: iad (US East)
- Auto-sleep: Enabled (saves costs, ~2-5s cold start)

**Database:** Fly Managed Postgres

- Connection: `pgbouncer.1zvn90kjp6xrkpew.flympg.net`
- Type: Managed Postgres (mpg)
- Includes: Backups, monitoring

**Redis:** `deshojo`

- Type: Upstash Redis (Pay-as-you-go)
- Connection: Set via REDIS_URL secret

## Staging Resources

**App:** `coffee-staging`

- URL: https://coffee-staging.fly.dev
- Region: iad (US East)
- Auto-sleep: Enabled (stops when idle)

**Database:** `coffee-staging-pg`

- Type: Postgres 17.2 (unmanaged)
- Size: shared-cpu-1x, 1GB volume
- Connection: Set via DATABASE_URL secret

**Redis:** `coffee-staging-redis`

- Type: Upstash Redis (Pay-as-you-go)
- Connection: Set via REDIS_URL secret
- Note: Optional - can delete if not testing background jobs

## Configuration

## Configuration

**Production Secrets:**

- `RAILS_MASTER_KEY`
- `DATABASE_URL` (Managed Postgres)
- `REDIS_URL` (deshojo Upstash)
- `APP_HOST=acercoffee.com`
- `SENDGRID_API_KEY`
- `SENDGRID_DOMAIN=acercoffee.com`
- `STRIPE_PUBLISHABLE_KEY` (test mode)
- `STRIPE_SECRET_KEY` (test mode)
- `STRIPE_WEBHOOK_SECRET` (test mode)

**Staging Secrets:**

- `RAILS_ENV=staging`
- `RAILS_MASTER_KEY` (from config/master.key)
- `DATABASE_URL` (auto-set by Postgres attach)
- `REDIS_URL`
- `SENDGRID_API_KEY` (shared with production)
- `STRIPE_PUBLISHABLE_KEY` (test mode)
- `STRIPE_SECRET_KEY` (test mode)
- `STRIPE_WEBHOOK_SECRET` (test mode)

## Deployment

**Production Deploy:**

```bash
flyctl deploy --app coffee-production
# Or use the parity helper: production deploy
```

**Staging Deploy:**

```bash
flyctl deploy --config fly.staging.toml
# Or use the parity helper: staging deploy
```

**Via GitHub Actions:**

- Push to `main` → auto-deploy to production
- Push to `staging` → auto-deploy to staging

## Usage (via Parity Helper)

Load the helper first:

```bash
source bin/fly-parity
```

**Common Commands:**

```bash
# Production
production console   # or: pc
production logs      # or: pl
production ssh
production db:migrate  # or: pdb
production status

# Staging
staging console      # or: sc
staging logs         # or: sl
staging ssh
staging db:migrate   # or: sdb
staging status
```

**Direct flyctl Commands:**

```bash
# Production
flyctl ssh console --app coffee-production
flyctl logs --app coffee-production
flyctl ssh console --app coffee-production -C "/rails/bin/rails console"

# Staging
flyctl ssh console --app coffee-staging
flyctl logs --app coffee-staging
flyctl ssh console --app coffee-staging -C "/rails/bin/rails console"
```

## Cost Estimate

**Production (currently auto-sleeping):**

- App machines: ~$7/mo (2x shared-cpu-1x, auto-stop when idle)
- Sidekiq workers: ~$7/mo (2x shared-cpu-1x)
- Managed Postgres: ~$10-30/mo (based on usage)
- Redis (deshojo): ~$0-5/mo

**Total Production: ~$24-49/mo**

**Staging (auto-sleeping):**

- App machines: ~$7/mo (2x shared-cpu-1x, auto-stop when idle)
- Sidekiq workers: ~$7/mo (2x shared-cpu-1x)
- Postgres: $0/mo (free tier)
- Redis: ~$0-5/mo (can delete if not testing jobs)

**Total Staging: ~$14-19/mo**

**Combined Total: ~$38-68/mo** (vs ~$56/mo on Heroku)

## Auto-Sleep Behavior

Both production and staging use auto-sleep to save costs:

- Machines stop after ~5-10 minutes of no traffic
- First request after idle has ~2-5 second cold start delay
- Subsequent requests are instant until idle again

**To disable auto-sleep (production when launching):**
Edit `fly.toml` and change:

```toml
min_machines_running = 0  # Change to 1 for always-on
```

## Important Notes

- Production and staging are completely separate apps
- Production uses Managed Postgres (automatic backups)
- Staging uses unmanaged Postgres (you manage backups)
- Both share the same SendGrid account
- Stripe keys are test mode on both (switch to live when ready)
- GitHub Actions auto-deploy on push to main (production) or staging branch

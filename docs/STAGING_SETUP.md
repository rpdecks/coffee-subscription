# Staging Environment Setup

## Fly.io Staging Resources

**App:** `coffee-staging`

- URL: https://coffee-staging.fly.dev
- Region: iad (US East)

**Database:** `coffee-staging-pg`

- Type: Postgres 17.2
- Size: shared-cpu-1x, 1GB volume
- Connection: Set via DATABASE_URL secret

**Redis:** `coffee-staging-redis`

- Type: Upstash Redis (Pay-as-you-go)
- Connection: Set via REDIS_URL secret

## Configuration

**Secrets Set:**

- `RAILS_ENV=staging`
- `RAILS_MASTER_KEY` (from config/master.key)
- `DATABASE_URL` (auto-set by Postgres attach)
- `REDIS_URL`
- `SENDGRID_API_KEY` (production key)
- `STRIPE_PUBLISHABLE_KEY` (test mode)
- `STRIPE_SECRET_KEY` (test mode)
- `STRIPE_WEBHOOK_SECRET` (test mode)

## Deployment

**Manual Deploy:**

```bash
flyctl deploy --config fly.staging.toml
```

**Via GitHub Actions:**

- Push to `staging` branch to auto-deploy

## Usage

**SSH Console:**

```bash
flyctl ssh console --app coffee-staging
```

**Rails Console:**

```bash
flyctl ssh console --app coffee-staging -C "/rails/bin/rails console"
```

**View Logs:**

```bash
flyctl logs --app coffee-staging
```

**Run Migrations:**

```bash
flyctl ssh console --app coffee-staging -C "./bin/rails db:migrate"
```

## Cost Estimate

- **App machines:** ~$7/mo (2x shared-cpu-1x)
- **Sidekiq workers:** ~$7/mo (2x shared-cpu-1x)
- **Postgres:** $0/mo (free tier)
- **Redis:** ~$0-5/mo (very light usage)

**Total: ~$14-19/mo** (same as production)

## Next Steps

1. ✅ Staging app created
2. ✅ Database and Redis provisioned
3. ⏳ Initial deployment in progress
4. 🔲 Create GitHub Action workflow for staging deploys
5. 🔲 Test staging environment
6. 🔲 Remove Heroku staging app to save costs

# Production Deployment Protection

## Current Setup (Pre-Launch)

✅ **GitHub Actions enabled** - Tests run on every push to `main`
✅ **Automatic deployment** - Deploys to Fly after tests pass
✅ **Manual safety script** - `bin/deploy-production` for local deploys

### How it works now (pre-launch):
```bash
# Option 1: Push to main (quick, for solo development)
git push origin main
# → GitHub runs tests
# → If tests pass, auto-deploys to Fly
# → If tests fail, no deployment happens

# Option 2: Deploy manually (with extra confirmation)
bin/deploy-production
# → Runs tests locally
# → Asks for confirmation
# → Deploys to Fly
```

### Rollback if needed:
```bash
fly releases              # See last 10 deployments
fly releases rollback     # Go back to previous version
```

## When You Have Customers (Post-Launch)

Enable these additional protections:

### 1. Protected Branch Rules
Go to GitHub → Settings → Branches → Add rule for `main`:
- ✅ Require a pull request before merging
- ✅ Require approvals (1+)
- ✅ Require status checks to pass (tests)
- ✅ Include administrators (even you need to follow rules)

### 2. Staging Environment
```bash
# Create staging app
fly apps create coffee-staging

# Copy fly.toml to fly.staging.toml
# Deploy to staging first:
fly deploy -c fly.staging.toml
```

### 3. Deploy Windows (optional)
Only allow deployments during off-peak hours.

### Setup:
1. Go to GitHub → Settings → Branches → Add rule for `main`
2. Enable "Require a pull request before merging"
3. Enable "Require status checks to pass"
4. Add Fly deploy token to GitHub Secrets

### Benefits:
- Can't deploy directly to production
- Must go through PR → approval → merge → auto-deploy
- Tests run automatically
- Deployment history in GitHub

### GitHub Action File:
Create `.github/workflows/fly-deploy.yml`:

```yaml
name: Deploy to Fly
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.0
      - name: Run tests
        run: |
          bundle install
          bundle exec rspec
      - name: Deploy to Fly
        uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

## Option 2: Fly Deploy Tokens (Simple Protection)

### Revoke your personal token:
```bash
# Remove ability to deploy with your current token
fly auth logout

# Create a deploy-only token (limited permissions)
fly auth token create deploy-only --app coffee-production
```

### Use token only in script:
Store token in 1Password/env var, only accessible via the safe script.

## Option 3: Fly Organizations + RBAC

### In Fly Dashboard:
1. Go to https://fly.io/dashboard/personal/settings
2. Create an Organization (if you haven't)
3. Invite yourself with "Deploy only" permissions
4. Revoke "Owner" access from CLI tokens

This limits what `fly deploy` can do from CLI.

## Option 4: Git Hooks (Local Protection)

Add to `.git/hooks/pre-push`:

```bash
#!/bin/bash
if git remote -v | grep -q "production"; then
  echo "🚨 BLOCKED: Cannot push to production directly"
  echo "Use: bin/deploy-production"
  exit 1
fi
```

## Recommended Setup:

**For solo developer (you):**
1. ✅ Use `bin/deploy-production` (done)
2. ✅ GitHub Actions for automatic deployment (after PR merge)
3. ✅ Protected `main` branch (require PR)

**For team:**
- Add Fly RBAC roles
- Require 2+ approvals on PRs
- Separate staging environment

Want me to set up the GitHub Action workflow?

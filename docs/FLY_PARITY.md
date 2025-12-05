# Fly.io Parity Helper

A Heroku parity-like helper for managing Fly.io staging and production environments.

## Setup

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Fly.io environment helpers
source ~/Development/code/coffee/bin/fly-parity
```

Then reload: `source ~/.zshrc`

## Usage

### Basic Commands

```bash
# Staging
staging console       # Open Rails console
staging logs          # Tail logs
staging ssh           # SSH into machine
staging db:migrate    # Run migrations
staging deploy        # Deploy to staging
staging status        # Check app status

# Production
production console    # Open Rails console
production logs       # Tail logs
production ssh        # SSH into machine
production db:migrate # Run migrations
production deploy     # Deploy to production
production status     # Check app status
```

### Aliases

```bash
sc   # staging console
pc   # production console
sl   # staging logs
pl   # production logs
sdb  # staging db:migrate
pdb  # production db:migrate
```

## Examples

```bash
# Open staging console
sc

# Tail production logs
pl

# Run migrations on staging
sdb

# Deploy to production
production deploy

# Check staging status
staging status
```

## Comparison to Heroku Parity

| Heroku Parity | Fly Parity |
|---------------|------------|
| `staging console` | `staging console` or `sc` |
| `production console` | `production console` or `pc` |
| `staging tail` | `staging logs` or `sl` |
| `production tail` | `production logs` or `pl` |

The syntax is nearly identical to the parity gem you're used to!

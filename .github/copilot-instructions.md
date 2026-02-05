# Copilot / Agent instructions (Coffee)

These are repo-specific rules for automated edits and CLI usage.

## Ground rules

- Prefer using VS Code Tasks defined in `.vscode/tasks.json` over ad-hoc commands.
- Keep changes minimal and scoped to the request.
- Do not change branding/design decisions unless explicitly requested.
- Do not add new pages or UX beyond what the user asks.

## Commands

### Safe to run without asking

- `bin/rspec` (and `bin/rspec <path>`)
- `bin/rubocop`
- `bin/brakeman`
- `bin/rails routes`
- `bin/rails runner ...` (read-only scripts only)

#### Git / GitHub (read-only)

- `git status`, `git diff`, `git log`, `git show`
- `gh auth status`
- `gh pr status`, `gh pr list`, `gh pr view`, `gh pr checks`
- `gh run list`, `gh run view --log-failed`
- `gh workflow list`, `gh workflow view`

#### Fly.io (read-only)

- `fly status`, `fly logs`, `fly releases`
- `fly apps list`, `fly info`

### Ask first (destructive / irreversible)

- Any `db:drop`, `db:reset`, `db:purge`
- Any migration generation (`bin/rails g migration ...`) or schema changes
- Any command that modifies production/staging configuration or deploys (`fly`, `bin/deploy-production`, etc.)
- Any command that writes to `config/credentials*`

#### Fly.io (deployment / secrets)

- Any `fly deploy`
- Any `fly secrets set` / `fly secrets import`
- Any change to Fly config files (`fly.toml`, `fly.*.toml`)

#### Git / GitHub (history rewriting / potentially risky)

- Any `git rebase` that rewrites shared history
- Any `git push --force` / `--force-with-lease`
- Any branch deletion on remote (`git push origin --delete ...`)
- Any `gh pr merge` (always confirm merge method + target branch)

Git/GitHub write actions like creating branches, committing, pushing, and opening PRs are OK when the user explicitly requests them, but should not be done implicitly as part of “investigation”.

If asked to “fix CI”, prefer inspecting with `gh pr checks` / `gh run view --log-failed` first, then propose the smallest code change that fixes the failure.

## Rails conventions in this repo

- Dev entrypoint: `bin/dev` (uses `foreman` + `Procfile.dev`).
- Tests: RSpec via `bin/rspec`.
- Linting: `bin/rubocop`.
- Security scan: `bin/brakeman`.

## When debugging

- Reproduce first, then locate: route → controller → policy/service → view.
- If you change behavior, add/adjust an RSpec example when feasible.

## Output expectations

- Provide a short recap of what changed and where.
- Call out any risks (migrations, data changes, auth/policy impacts).

# Agent workflows (VS Code + gh)

This repo is set up so agents can reliably run common workflows via VS Code Tasks and the GitHub CLI (`gh`).

## Daily “solo wins”

### 1) One command quality gate

Run the default Build task:

- Task: **Quality: rubocop + brakeman + rspec**

This is the fastest way to validate a change before pushing.

### 2) CI failure triage (without leaving VS Code)

Use these tasks:

- **GH: PR checks (current branch)**
- **GH: view latest failed run logs**
- **GH: runs list (10)**

Typical flow:

1. Run **GH: PR checks (current branch)**
2. If something failed, run **GH: view latest failed run logs**
3. Make the smallest fix, then run the default Build task again

### 3) PR workflow

- Create PR: **GH: PR create (interactive)**
- View PR: **GH: PR view (current branch)**
- Mark ready: **GH: PR ready (mark ready for review)**
- Comment/review: **GH: PR comment** / **GH: PR review (comment)**

## Guardrails (important)

Agents may run read-only git/gh commands freely, but must ask first before:

- `git push --force` / history rewrites
- risky rebases on shared branches
- remote branch deletion
- merging PRs

See `.github/copilot-instructions.md` for the full list.

## Common snags & fixes

### `gh auth status` shows not logged in

Run in your terminal:

- `gh auth login`

### `gh pr checks` says no PR found

You’re probably on a branch without a PR yet.

- Create one with **GH: PR create (interactive)**

### CI failed but logs are missing

Some workflows restrict log access for tokens. Try:

- **GH: runs list (10)** then open the run in the browser
- Or run `gh run view <id> --web`

## Suggested prompt patterns

When delegating to an agent, give a tight definition of done:

- “Inspect CI failures for this branch using `gh pr checks` and `gh run view --log-failed`, then propose the smallest fix and run `bin/rspec` for impacted specs.”
- “Open a PR for the current branch using `gh pr create`, using title/body based on the last 3 commits.”
- “Summarize the last failed run and paste the failing test names + error excerpts.”

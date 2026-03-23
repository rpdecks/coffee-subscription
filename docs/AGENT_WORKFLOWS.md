# Agent workflows (VS Code + gh)

This repo is set up so agents can reliably run common workflows via VS Code Tasks and the GitHub CLI (`gh`).

## Daily “solo wins”

## PDF Intake Workflow

For repeatable agent-driven ingestion of coffee fact sheets, use a stable local folder:

- Repo-local working folder: `/Users/robertphillips/Development/code/coffee/tmp/agent-inputs`

This folder is already safe for working files because `/tmp/*` is ignored by git.

If you keep source PDFs in Google Drive, that also works as long as the folder is synced to your Mac and available as a normal filesystem path. Example shape:

- `/Users/<you>/Library/CloudStorage/GoogleDrive-.../My Drive/Acer Coffee/Green Coffee Info Sheets`

Recommended flow:

1. Keep your long-term archive in Google Drive if that is where you organize supplier sheets.
2. Drop the PDFs you want processed into `tmp/agent-inputs` for stable local automation.
3. Use the `draft_products_from_folder` MCP tool to process all PDFs in that folder into structured product drafts.
4. Use the `create_product_from_pdf` or `create_product_from_draft` MCP tools to create the local product record.

## Roast + Package Workflow

Once a coffee product exists, shop stock comes from packaged inventory, not from the green coffee lot.

Recommended flow:

1. Keep the source bean tracked in Green Coffee inventory.
2. Use the `record_roast_and_package_inventory` MCP tool when you roast and bag coffee.
3. Pass the product ID, optional green coffee ID, roast date, roasted pounds, and packaged pounds.
4. The tool will record roasted output, create packaged inventory, debit roasted inventory used for packaging, and optionally reduce the GreenCoffee lot quantity.

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

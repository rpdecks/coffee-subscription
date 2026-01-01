# Designer Bot Brief (Acer Coffee)

This document is the **working contract** for a designer-bot (or human designer) iterating on Acer Coffee’s brand.

If you follow this brief, your output will be directly usable by:

- engineering (Rails views + Tailwind)
- print production (bag labels)

## What you must use as inputs

Treat these as the current source of truth:

- `docs/brand/tokens.md` (colors, typography, spacing, radii)
- `docs/brand/logo.md` (logo/icon rules)
- `docs/brand/print/labels.md` (print constraints + checklist)

Helpful references:

- Existing web assets: `app/assets/images/brand/`
- Tailwind token implementation: `config/tailwind.config.js`

## What you are allowed to change

You may propose:

- updates to `docs/brand/tokens.md` and/or `docs/brand/logo.md`
- new/updated exports (SVG/PNG/PDF) placed in the correct repo folders

You should NOT:

- invent one-off hex colors that aren’t added as a token first
- change filenames that engineering might already reference (unless you also provide a migration plan)

## Required outputs (what “done” looks like)

### Web exports (commit to repo)

Destination: `app/assets/images/brand/`

Required formats:

- Logos/icons: SVG (primary)
- Raster previews (when needed): PNG

### Print exports (commit to repo)

Destination: `docs/brand/print/exports/`

Required formats:

- Print-ready: vector PDF (with bleed; fonts embedded or outlined per printer)
- Proof (optional): PNG

## Naming conventions

### Web

Prefer stable, short names:

- `logo.svg`
- `acer-watermark.svg`
- `cultivar-icons/<name>.svg`

### Print

Deterministic naming for easy reprints:

- `acer-label-front_v01_YYYY-MM-DD.pdf`
- `acer-label-front_v01_YYYY-MM-DD.png`

## Acceptance checklist

Web (icons/logos):

- Reads at 16–20px (for UI icons)
- Looks correct on `espresso` background
- Can be used accessibly (paired label text or `aria-label` if used as a control)

Print (labels):

- Bleed + safe area applied
- Text legible at actual physical size
- CMYK conversion reviewed (especially deshojo red)

## How you should respond (format)

When you propose an iteration, respond with:

1. **Doc changes**

- File: `docs/brand/tokens.md` (or `docs/brand/logo.md` / `docs/brand/print/labels.md`)
- Provide the exact new text to add/replace

2. **Export list**

- `path/to/file.svg` — what it is + any constraints (size, color, usage)
- `path/to/file.pdf` — print spec (bleed, safe area)

3. **Notes / risks**

- Anything engineering or the printer needs to know (e.g., stroke weight changes, CMYK concerns)

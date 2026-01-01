# Designer Interface (How we collaborate)

This doc defines the **interface** between:

- Design work (icons, typography choices, label layouts)
- Engineering work (Rails views + Tailwind tokens)
- Print production (bag label files)

If we follow this, we can iterate fast without losing decisions or breaking consistency.

---

## 1) Inputs we provide to the designer

### Brand rules (source of truth)

- `docs/brand/tokens.md` (colors, type, spacing/radii)
- `docs/brand/logo.md` (logo/icon usage + exports)
- `docs/brand/print/labels.md` (printer checklist + label spec)

### Technical constraints (so designs implement cleanly)

- Stack: Rails SSR views + Tailwind CSS
- Preferred approach: use Tailwind semantic tokens (e.g. `espresso`, `cream`, `deshojo`) rather than inventing new hexes ad-hoc.
- Dark-mode first: designs should assume `espresso` background unless explicitly noted.

### References

- Existing assets the app already uses live in `app/assets/images/brand/`.

---

## 2) Outputs we expect back from the designer

Think in terms of **"source"** vs **"exports"**.

### A) Source of truth (designer tool)

- Usually a Figma file (preferred) or Illustrator document.
- This repo does **not** need to contain that source file if it’s large; a link is fine.

### B) Web exports (must be committed)

Commit to `app/assets/images/brand/`.

- Logo / icon: `SVG` (primary)
- Social preview / raster fallback: `PNG`
- If a favicon/app icon set is needed: provide a single square master + generated set

**Important:** Keep filenames stable after engineering uses them.

### C) Print exports (must be committed)

Commit to `docs/brand/print/exports/` (we’ll create this when you’re ready), or attach to the printer handoff.

- Print-ready: vector `PDF` (with bleed; fonts embedded/outlined per printer)
- Proof: `PNG` (optional)

---

## 3) Decision protocol (how changes get approved)

### Token changes (colors, fonts, radii)

1. Propose change as an update to `docs/brand/tokens.md`.
2. Engineer updates `config/tailwind.config.js` to match.
3. Only then should UI/components adopt the new token.

This avoids “mystery colors” that exist only in mockups.

### Logo/icon changes

1. Update the spec in `docs/brand/logo.md`.
2. Replace exports in `app/assets/images/brand/`.
3. Note what changed (stroke width, joins, simplified form) in the Decisions log.

### Print label changes

1. Update requirements in `docs/brand/print/labels.md`.
2. Add/update print exports in the print exports location.

---

## 4) Naming conventions (so assets are predictable)

### Web assets

- Prefer short, stable names:
  - `logo.svg`
  - `acer-watermark.svg`
  - `cultivar-icons/deshojo.svg` (example)

### Print exports

Use deterministic names so reprints are easy:

- `acer-label-front_v01_YYYY-MM-DD.pdf`
- `acer-label-front_v01_YYYY-MM-DD.png`

---

## 5) Quality checklist (what “done” means)

### Web (SVG/icon)

- Reads at small sizes (16–20px for UI icons)
- Looks good on `espresso` background
- Accessible usage possible (label text or `aria-label` when used as controls)

### Print (labels)

- Bleed + safe area set
- Text legible at actual physical size
- CMYK conversion reviewed (especially deshojo red)

---

## 6) How to use this in another chat

If you’re spinning up a “designer bot” chat, point it at:

- `docs/brand/tokens.md`
- `docs/brand/logo.md`
- `docs/brand/print/labels.md`
- `app/assets/images/brand/` (existing icon direction)

…and ask it to only propose changes that can be expressed as:

- an update to tokens/spec docs, and
- a set of concrete exports with stable filenames.

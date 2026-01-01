# Brand Style Guide (Acer Coffee)

This folder is the **single source of truth** for Acer Coffee’s branding decisions and how they map into the Rails + Tailwind implementation.

## Why this exists

Brand work tends to sprawl (fonts, colors, icons, print files, exports). Keeping it here:

- preserves decisions in Git history
- keeps "what we decided" close to "what we shipped"
- makes it easy to collaborate with a designer without losing track of latest exports

## Where things live

- Decisions + specs: this folder (`docs/brand/*`)
- Web-ready brand assets used by the app: `app/assets/images/brand/`
- Tailwind tokens (code): `config/tailwind.config.js`

## Files to read first

- `tokens.md`: colors, typography, spacing, radii/shadows
- `logo.md`: icon/logo rules, usage, export requirements
- `print/labels.md`: packaging label spec + printer/export checklist
- `DESIGNER_BOT_BRIEF.md`: contract for designer-bot iterations (inputs/outputs/exports)

## How to work with a designer

1. **Decide** in `tokens.md` and `logo.md`.
2. Keep editable source-of-truth files in the designer’s tool (usually Figma).
3. Save only **exports that the app or printer needs** into this repo.
4. Update these docs when a decision changes.

## How this maps to the app

- Use Tailwind semantic tokens (e.g. `bg-espresso`, `text-cream`, `bg-deshojo`) instead of ad-hoc hex values.
- If a new color/font is introduced, update `config/tailwind.config.js` first, then reference the token in views.

## Related existing docs

This repo already contains earlier branding notes at the root:

- `BRAND_IMPLEMENTATION_BRIEF.md`
- `BRANDING_DECISIONS.md`
- `BRANDING_SNAPSHOT.md`

Those are still useful; this folder is the ongoing, implementation-aligned version.
